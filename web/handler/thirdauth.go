package handler

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"math/rand"
	"net/http"
	"net/url"
	"time"

	"github.com/aitour/scene/model"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/facebook"
	"golang.org/x/oauth2/google"
)

var (
	qqClientId = ""
	authStates = make(map[string]int64)
)

func AuthQQ(c *gin.Context) {
	// qqClientId := ""
	// redirectUrl := ""
	// responseType := "code"
	// state := ""
	// url := `https://graph.qq.com/oauth2.0/show?which=Login&display=pc&client_id=101284669&redirect_uri=https%3A%2F%2Fgitee.com%2Fauth%2Fqq_connect%2Fcallback&response_type=code&state=4188dd9902cf5bb2c8279a0557324b1860db3f5d000ece56`
}

func AuthWechat(c *gin.Context) {

}

func AuthWeibo(c *gin.Context) {

}

func bindOpenId(platform string,
	email string,
	openid string,
	name string,
	picture string,
	locale string) (*model.User, error) {
	//检查数据库是否存在Email对应的账户
	user, err := model.VerifyUserByOpenId(platform, openid)
	if err != nil {
		fmt.Printf("model.VerifyUserByOpenId error: %v\n", err)
		return nil, err
	}
	// if err != nil {
	// 	log.WithFields(log.Fields{"err": err}).Error("Verify user by openid error")
	// 	c.HTML(http.StatusOK, "signin.html", gin.H{
	// 		"error": err,
	// 	})
	// 	return
	// }

	if user == nil {
		//创建并绑定账户
		if user, err = model.BindOpenId(platform, email, openid); err != nil {
			log.WithFields(log.Fields{"err": err, "platform": platform, "email": email, "openid": openid}).Error("bind user error")
			return nil, err
		}

		//设置avartar
		log.WithFields(log.Fields{"uid": user.Id, "avatar": picture}).Info("set user profile")
		err = model.SetUserProfile(user.Id, map[string]string{
			"nickname": name,
			"avatar":   picture,
			"lang":     locale,
		})
		if err != nil {
			log.WithFields(log.Fields{"err": err}).Error("set user profile error")
			return nil, err
		}
		user.Name = name
		user.Email = email
		user.Avatar = picture
		user.Locale = locale
	} else {
		//read user info
		profile, err := model.GetUserProfile(user.Id)
		if err != nil {
			return nil, err
		}
		user.Name = profile.NickName
		user.Email = profile.Email
		user.Avatar = profile.Avatar
		user.Locale = profile.Lang
	}

	return user, nil
}

func bindGoogle(c *gin.Context) {
	fbConfig := oauth2.Config{
		ClientID:     "216679058012-21gqlhp3eh1qp4mmvtmag7298h991udb.apps.googleusercontent.com",
		ClientSecret: "OWwBt-b2XVz5qLDeGDaKEsVJ",
		RedirectURL:  "https://" + cfg.Http.Domain + "/openid/google",
		Scopes: []string{
			"https://www.googleapis.com/auth/plus.me",
			"https://www.googleapis.com/auth/userinfo.email",
			"https://www.googleapis.com/auth/userinfo.profile",
		},
		Endpoint: google.Endpoint,
	}

	state := c.Query("state")
	if len(state) == 0 {
		state = fmt.Sprintf("%d_%d", time.Now().UnixNano(), rand.Int31())
		authStates[state] = time.Now().UnixNano()
		authCodeURL := fbConfig.AuthCodeURL(state)
		c.Redirect(http.StatusTemporaryRedirect, authCodeURL)
		return
	}

	if _, ok := authStates[state]; !ok {
		c.Writer.Write([]byte("invalid state"))
	}
	delete(authStates, state)

	code := c.Query("code")
	token, err := fbConfig.Exchange(oauth2.NoContext, code)
	if err != nil {
		log.WithFields(log.Fields{"err": err}).Warn("exchange token error")
	}

	response, err := http.Get("https://www.googleapis.com/oauth2/v2/userinfo?access_token=" + token.AccessToken)
	var userInfo struct {
		ID      string
		Name    string
		Email   string
		Picture string
		Gender  string
		Locale  string
	}
	content, _ := ioutil.ReadAll(response.Body)
	if err := json.Unmarshal(content, &userInfo); err != nil {
		log.WithFields(log.Fields{"err": err, "content": content}).Error("decode facebook user info error")
		c.HTML(http.StatusOK, "signin.html", gin.H{
			"error": err,
		})
		return
	}
	user, err := bindOpenId("fb", userInfo.Email, userInfo.ID, userInfo.Name, userInfo.Picture, userInfo.Locale)
	if err != nil {
		c.HTML(http.StatusOK, "signin.html", gin.H{
			"error": err,
		})
	}
	signInUser(c, user.Id)
	// defer response.Body.Close()
	// contents, err := ioutil.ReadAll(response.Body)
	// fmt.Fprintf(c.Writer, "Content: %s\n", contents)
}

func bindFaceBook(c *gin.Context) {
	fbConfig := oauth2.Config{
		ClientID:     "186885222135849",
		ClientSecret: "8aac6edf699e196fd9259c86d07d2414",
		RedirectURL:  "https://" + cfg.Http.Domain + "/openid/facebook",
		Scopes:       []string{"public_profile", "email"}, //, "user_hometown", "user_birthday", "user_gender"
		Endpoint:     facebook.Endpoint,
	}

	state := c.Query("state")
	if len(state) == 0 {
		state = fmt.Sprintf("%d_%d", time.Now().UnixNano(), rand.Int31())
		authStates[state] = time.Now().UnixNano()
		authCodeUrl := fbConfig.AuthCodeURL(state)
		c.Redirect(http.StatusTemporaryRedirect, authCodeUrl)
		return
	}

	if _, ok := authStates[state]; !ok {
		fmt.Fprintf(c.Writer, "invalid state:%s", state)
		return
	}
	delete(authStates, state)

	code := c.Query("code")
	token, err := fbConfig.Exchange(oauth2.NoContext, code)
	if err != nil {
		log.WithFields(log.Fields{"err": err}).Warn("exchange token error")
	}

	user, err := associateFacebookToken(token.AccessToken)
	if err != nil {
		c.HTML(http.StatusOK, "signin.html", gin.H{
			"error": err,
		})
	}
	signInUser(c, user.Id)
}

func associateFacebookToken(fbAccessToken string) (*model.User, error) {
	query := &url.Values{}
	query.Set("access_token", fbAccessToken)
	query.Set("fields", "id,name,email,picture.type(small)")
	query.Set("method", "get")
	query.Set("sdk", "joey")
	query.Set("suppress_http_code", "1")
	response, err := http.Get("https://graph.facebook.com/v2.8/me?" + query.Encode())
	if err != nil {
		fmt.Printf("http graph get err: %v\n", err)
		return nil, err
	}

	var userInfo struct {
		ID      string
		Name    string
		Email   string
		Picture struct {
			Data struct {
				Width  int
				Height int
				Url    string
			}
		}
	}

	content, _ := ioutil.ReadAll(response.Body)
	if err := json.Unmarshal(content, &userInfo); err != nil {
		log.WithFields(log.Fields{"err": err, "content": content}).Error("decode facebook user info error")
		fmt.Printf("json decode error: %v\n", err)
		return nil, err
	}
	return bindOpenId("fb", userInfo.Email, userInfo.ID, userInfo.Name, userInfo.Picture.Data.Url, "")
}

func associateFaceBookTokenHandler(c *gin.Context) {
	accessToken := c.PostForm("access_token")
	if len(accessToken) == 0 {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}
	user, err := associateFacebookToken(accessToken)
	if err != nil {
		print(err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	uid := fmt.Sprintf("%d", user.Id)
	token, _ := tokenProvider.AssignToken(uid)

	c.JSON(http.StatusOK, map[string]string{
		"uid":          fmt.Sprintf("%d", user.Id),
		"email":        user.Email,
		"access_token": token,
		"name":         user.Name,
	})
}

func SetupThirdPartyAuthHandlers(r *gin.Engine) {
	r.GET("/openid/qq", AuthQQ)
	r.GET("/openid/weixin", AuthWechat)
	r.GET("/openid/weibo", AuthWeibo)

	r.GET("/openid/google", bindGoogle)
	r.GET("/openid/facebook", bindFaceBook)
	r.POST("/associate/facebook", associateFaceBookTokenHandler)
}
