package main

import (
	"context"
	"flag"
	"html/template"
	"net/http"
	"os"
	"fmt"
	"os/signal"
	"syscall"
	"time"
	"path"

	//for image decode
	_ "image/jpeg"
	_ "image/png"

	"github.com/aitour/scene/web/config"
	"github.com/aitour/scene/web/handler"
	"github.com/gin-contrib/cors"

	"github.com/dchest/captcha"
	"github.com/gin-gonic/gin"

	log "github.com/sirupsen/logrus"
)

var (
	conf = flag.String("conf", "web.toml", "Specify a config file")
	cfg  *config.Config
)

func createHTTPServer() (*http.Server, error) {
	log.SetOutput(gin.DefaultWriter)

	r := gin.Default()
	// Set a lower memory limit for multipart forms (default is 32 MiB)
	//r.MaxMultipartMemory = 8 << 20 // 8 MiB

	//cross domain request config.
	r.Use(cors.New(cors.Config{
		AllowAllOrigins: true,
		//AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"POST", "GET", "DELETE", "PUT", "PATCH"},
		AllowHeaders:     []string{"Origin", "X-Requested-With", "Content-Type", "Accept"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		// AllowOriginFunc: func(origin string) bool {
		// 	return origin == "*"
		// },
		MaxAge: 12 * time.Hour,
	}))

	r.Use(handler.AttachUserInfo())

	r.SetFuncMap(template.FuncMap{
		"T": handler.Tr,
	})
	r.LoadHTMLGlob(cfg.Http.AssetsDir + "/templates/*.html")
	r.Static("/assets", cfg.Http.AssetsDir)
	r.Static("/photo", cfg.Http.UploadDir)

	r.GET("/", func(c *gin.Context) {
		c.HTML(http.StatusOK, "index.html", gin.H{
			"title": "pangolins ai",
		})
	})

	handler.SetupThirdPartyAuthHandlers(r)

	r.GET("/user/register", func(c *gin.Context) {
		id := captcha.New()
		c.HTML(http.StatusOK, "register.html", gin.H{
			"cv":   id,
			"lang": c.DefaultQuery("lang", "en"),
		})
	})
	r.POST("/user/register", handler.CreateUser)
	r.GET("/user/activate", handler.ActivateUser)
	r.GET("/user/signin", handler.UserLogin)
	r.POST("/user/signin", handler.AuthUser)
	r.GET("/user/logout", handler.Logout)

	authorized := r.Group("/", handler.AuthChecker())
	authorized.GET("/user", func(c *gin.Context) {
		c.HTML(http.StatusOK, "profile.html", gin.H{})
	})
	authorized.GET("/user/photos", handler.GetUserPhotos)
	authorized.GET("/user/profile", handler.GetUserProfile)
	authorized.POST("/user/setprofile", handler.SetUserProfile)
	authorized.GET("/user/changepwd", handler.ChangePwd)
	authorized.POST("/user/changepwd", handler.ChangePwd)
	r.GET("/demo", func(c *gin.Context) {
		c.HTML(http.StatusOK, "demo.html", gin.H{
			"title": "predict demo page",
		})
	})
	r.GET("/demo2", func(c *gin.Context) {
		c.HTML(http.StatusOK, "demo2.html", gin.H{
			"title": "predict demo page offline",
		})
	})

	r.GET("/demo/testimgs/:site", handler.FetchTestImages)

	r.GET("/demo_porcelain", func(c *gin.Context) {
		c.HTML(http.StatusOK, "demo_porcelain.html", gin.H{
			"title": "predict demo page",
		})
	})

	r.GET("/art/:id", handler.GetArtById)

	r.POST("/uploadimg", handler.UploadAnonomousePhoto)
	r.POST("/setimgclass", handler.SetAnonomouseUploadedPhotoClass)
	r.POST("/uploadscale", func(c *gin.Context) {
		if c.PostForm("auth") != "135246" {
			c.JSON(http.StatusBadRequest, nil)
			return
		}
		form, _ := c.MultipartForm()
		files := form.File["files"]
		if len(files) == 0 {
			files = form.File["files[]"]
		}
		//log.Printf("form:%+v, files:%d", form, len(files))
		for _, file := range files {
			dst := path.Join(config.GetConfig().Http.UploadDir, fmt.Sprintf("%d%s", time.Now().UnixNano(), path.Ext(file.Filename)));
			//log.Printf("upload file:%v -> %v", file.Filename, dst)
			c.SaveUploadedFile(file, dst)
		}
		c.JSON(http.StatusOK, nil)
	})

	r.POST("/predict", handler.Predict)
	r.POST("/predict2", handler.Predict2)
	r.GET("/weather/current", handler.GetCurrentWeather)
	r.GET("/weather/forecast", handler.GetWeatherForeCast)
	r.GET("/geocode", handler.GeoCodeHandler)
	r.GET("/nearby/city", handler.FindNearbyCityHandler)
	r.GET("/nearby/museum", handler.SearchNearbyMuseumsByGoogleMap)
	r.GET("/place/photo", handler.GetPlacePhoto)
	r.GET("/place/detail", handler.GetPlaceDetail)
	r.GET("/vcode/:img", gin.WrapH(captcha.Server(200, 60)))
	r.GET("/vcode", handler.NewCaptacha)

	r.GET("/model/list", handler.GetModelInfo)
	r.GET("/model/refresh", handler.RefreshModelInfo)

	s := &http.Server{
		Addr:    cfg.Http.Bind,
		Handler: r,
	}
	return s, nil
}

func main() {
	flag.Parse()

	//parse config
	var err error
	config.SetConfigPath(*conf)
	cfg = config.GetConfig()

	//create http server
	srv, err := createHTTPServer()
	if err != nil {
		log.Fatal(err)
	}

	//startup http server
	go func() {
		//if err := srv.ListenAndServeTLS("server.crt", "server.key"); err != nil {
		if err := srv.ListenAndServe(); err != nil {
			log.Fatal(err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server with
	// a timeout of 5 seconds.
	quit := make(chan os.Signal)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM, syscall.SIGINT, syscall.SIGKILL, syscall.SIGHUP, syscall.SIGQUIT)
	<-quit
	log.Println("Shutdown Server ...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal("Server Shutdown:", err)
	}
	log.Println("Server exiting")
}
