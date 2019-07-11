package net.pangolinai.mobile;

import android.annotation.TargetApi;
import android.graphics.Bitmap;
import android.graphics.Matrix;
import android.graphics.BitmapFactory;
import android.media.ExifInterface;
import android.renderscript.Allocation;
import android.renderscript.Element;
import android.renderscript.RenderScript;
import android.renderscript.ScriptIntrinsicYuvToRGB;
import android.renderscript.Type;
import android.os.Build;
import android.util.Log;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

import org.tensorflow.lite.Interpreter;

import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.util.ArrayList;
import java.util.Arrays;
//import java.util.Calendar;
import java.util.HashMap;
import java.util.List;

class FeatureEntry {
    int artId;
    double [] features;
    double featureNorm;
}

public class MuseumTfliteHandler implements MethodChannel.MethodCallHandler {
    public static final String CHANNEL = "net.pangolinai.mobile/museum_tflite";
    public static final String TAG = MuseumTfliteHandler.class.getName();
    private final PluginRegistry.Registrar mRegistrar;
    private Interpreter tfLite;
    float[][] labelProb;
    final static int CLASS_NUM = 1280;
    final static int IMAGE_SIZE = 224;
    final static int BYTES_PER_CHANNEL = 4;
    final static String OUTPUT_LAYER = "global_average_pooling2d_1";
    //final static List<double[]> predFeatures = new ArrayList<>();
    //final static List<Double> featuresNorm = new ArrayList<>();
    final static List<FeatureEntry> predFeatures = new ArrayList<>();


    public static void registerWith(PluginRegistry.Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), CHANNEL);
        channel.setMethodCallHandler(new MuseumTfliteHandler(registrar));
    }

    private MuseumTfliteHandler(PluginRegistry.Registrar registrar) {
        this.mRegistrar = registrar;
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        if (call.method.equals("loadModel")) {
            Log.e(TAG, "loadModel");
            try {
                String res = loadModel((HashMap) call.arguments);
                result.success(res);
            }
            catch (Exception e) {
                result.error("Failed to load model" , e.getMessage(), e);
            }
        }
//        else if (call.method.equals("runModelOnImage")) {
//            try {
//                float[] feature  = runModelOnImage((HashMap) call.arguments);
//                ByteBuffer buf = ByteBuffer.allocate(feature.length * 4).order(ByteOrder.LITTLE_ENDIAN);
//                for (int i = 0; i < feature.length; i++) {
//                    buf.putFloat(feature[i]);
//                }
//                result.success(buf.array());
//            }
//            catch (Exception e) {
//                result.error("Failed to run model" , e.getMessage(), e);
//            }
//        }
        else if (call.method.equals("runModelOnImage")) {
            try {
                ByteBuffer buf  = runModelOnImage((HashMap) call.arguments);
                result.success(buf.array());
            }
            catch (Exception e) {
                result.error("Failed to run model" , e.getMessage(), e);
            }
        }
        else if (call.method.equals("runModelOnBinary")) {
            try {
                float[] feature = runModelOnBinary((HashMap) call.arguments);
                ByteBuffer buf = ByteBuffer.allocate(feature.length * 4).order(ByteOrder.LITTLE_ENDIAN);
                for (int i = 0; i < feature.length; i++) {
                    buf.putFloat(feature[i]);
                }
                result.success(buf.array());
            }
            catch (Exception e) {
                result.error("Failed to run model" , e.getMessage(), e);
            }
        } else if (call.method.equals("close")) {
            close();
        }
    }

    private double norm(double []array) {
        if (array.length == 0) return 0;
        double avg = 0;
        for (int i = 0; i < array.length; i++) {
            avg += array[i];
        }
        avg = avg / array.length;
        double n = 0;
        for (int i = 0; i < array.length; i++) {
             n += (array[i] - avg) * (array[i] - avg);
        }
        return Math.sqrt(n);
    }

//    private double norm(float []array) {
//        if (array.length == 0) return 0;
//        double avg = 0;
//        for (int i = 0; i < array.length; i++) {
//            avg += array[i];
//        }
//        avg = avg / array.length;
//        double n = 0;
//        for (int i = 0; i < array.length; i++) {
//            n += (array[i] - avg) * (array[i] - avg);
//        }
//        return Math.sqrt(n);
//    }

    private String loadModel(HashMap args) throws IOException {
        String model = args.get("model").toString();
        String index = args.get("index").toString();
        Log.e(TAG, "model:" + model);
        Log.e(TAG, "index:" + index);
        //AssetManager assetManager = mRegistrar.context().getAssets();
        //String key = mRegistrar.lookupKeyForAsset(model);

        //AssetFileDescriptor fileDescriptor = assetManager.openFd(key);
        File f = new File(model);
        FileInputStream inputStream = new FileInputStream(f);
        FileChannel fileChannel = inputStream.getChannel();

        long startOffset = 0;
        long declaredLength = f.length();
        MappedByteBuffer buffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength);
        tfLite = new Interpreter(buffer);

        if (index != null && index.length() > 0) {
            Log.e(TAG, "load index file");
            DataInputStream dis = new DataInputStream(new FileInputStream(index));
            byte [] data = new byte[dis.available()];
            dis.readFully(data);
            ByteBuffer buf = ByteBuffer.wrap(data).order(ByteOrder.LITTLE_ENDIAN);
            int dimention = (int)buf.getFloat();
            Log.e(TAG, "dimention:" + dimention);
            if ((data.length - buf.position()) % ((dimention + 1) * 4) != 0) {
                Log.e(TAG, "invalid index file");
                return "false";
            }
            while(buf.position() < data.length) {
                try {
                    FeatureEntry entry = new FeatureEntry();
                    entry.artId = (int)buf.getFloat();
                    entry.features = new double[dimention];
                    for (int i = 0; i < dimention; i++) {
                        entry.features[i] = (double)buf.getFloat();
                    }
                    entry.featureNorm = norm(entry.features);
                    predFeatures.add(entry);
                }catch (Exception e) {
                    Log.e(TAG, "read index file error:"+ e.toString());
                }
            }
            Log.e(TAG, "load index file ok:" + predFeatures.size());
        }
        return "success";
    }

//    private ByteBuffer loadImage(String path, int width, int height, int channels, float mean, float std)
//            throws IOException {
//        InputStream inputStream = new FileInputStream(path.replace("file://",""));
//        Bitmap bitmapRaw = BitmapFactory.decodeStream(inputStream);
//
//        Matrix matrix = getTransformationMatrix(
//                bitmapRaw.getWidth(), bitmapRaw.getHeight(),
//                width, height, false);
//
//        int[] intValues = new int[width * height];
//        ByteBuffer imgData = ByteBuffer.allocateDirect(1 * width * height * channels * BYTES_PER_CHANNEL);
//        imgData.order(ByteOrder.nativeOrder());
//
//        Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
//        final Canvas canvas = new Canvas(bitmap);
//        canvas.drawBitmap(bitmapRaw, matrix, null);
//        bitmap.getPixels(intValues, 0, bitmap.getWidth(), 0, 0, bitmap.getWidth(), bitmap.getHeight());
//
//        int pixel = 0;
//        for (int i = 0; i < width; ++i) {
//            for (int j = 0; j < height; ++j) {
//                int pixelValue = intValues[pixel++];
//                imgData.putFloat((((pixelValue >> 16) & 0xFF) - mean) / std);
//                imgData.putFloat((((pixelValue >> 8) & 0xFF) - mean) / std);
//                imgData.putFloat(((pixelValue & 0xFF) - mean) / std);
//            }
//        }
//
//        return imgData;
//    }

    public Allocation renderScriptNV21ToRGBA888(android.content.Context context, int width, int height, byte[] nv21) {
        // https://stackoverflow.com/a/36409748
        RenderScript rs = RenderScript.create(context);
        ScriptIntrinsicYuvToRGB yuvToRgbIntrinsic = ScriptIntrinsicYuvToRGB.create(rs, Element.U8_4(rs));

        Type.Builder yuvType = new Type.Builder(rs, Element.U8(rs)).setX(nv21.length);
        Allocation in = Allocation.createTyped(rs, yuvType.create(), Allocation.USAGE_SCRIPT);

        Type.Builder rgbaType = new Type.Builder(rs, Element.RGBA_8888(rs)).setX(width).setY(height);
        Allocation out = Allocation.createTyped(rs, rgbaType.create(), Allocation.USAGE_SCRIPT);

        in.copyFrom(nv21);

        yuvToRgbIntrinsic.setInput(in);
        yuvToRgbIntrinsic.forEach(out);
        return out;
    }


    @TargetApi(Build.VERSION_CODES.FROYO)
    private List<ByteBuffer> loadImage(Bitmap bitmapRaw, int width, int corps, String imagePath)  throws IOException {
        int rawWidth = bitmapRaw.getWidth(), rawHeight = bitmapRaw.getHeight();
        int minSide = Math.min(rawWidth, rawHeight);
        float scale = (float)width / (float)minSide;
        Matrix matrix = new Matrix();
        matrix.postScale(scale, scale);
        if (imagePath != null && imagePath.length() > 0) {
            ExifInterface exif = new ExifInterface(imagePath);
            String orientation = exif.getAttribute(ExifInterface.TAG_ORIENTATION);
            //Log.e("tflite", String.format("rawWidth:%d, rawHeight:%d, orientation:%s", rawWidth, rawHeight, orientation));
            if (orientation.equals("6")) {
                matrix.postRotate(90);
            } else if (orientation.equals("3")) {
                matrix.postRotate(180);
            } else if (orientation.equals("8")) {
                matrix.postRotate(270);
            }
        }
        Bitmap scaledBmp = Bitmap.createBitmap(bitmapRaw, 0, 0, rawWidth, rawHeight, matrix, true);
//       MediaStore.Images.Media.insertImage(
//               mRegistrar.context().getContentResolver(),
//               scaledBmp,
//               "image_file",
//               "file");

        //write a scaled image to disk
        if (imagePath != null && imagePath.length() > 0) {
            String scaleFilePath = imagePath + ".scale";
            File file = new File(imagePath + ".scale");
            OutputStream fOutputStream = new FileOutputStream(file);
            scaledBmp.compress(Bitmap.CompressFormat.JPEG, 100, fOutputStream);
            fOutputStream.flush();
            fOutputStream.close();
            copyExif(imagePath, scaleFilePath);
        }

        Bitmap[] testBmp = { scaledBmp };
        List<ByteBuffer> buffers = new ArrayList<ByteBuffer>();
        int offsetStep = 0;
        if (corps > 1) {
            offsetStep = Math.abs(scaledBmp.getWidth() - scaledBmp.getHeight()) / (corps - 1);
        }
        int[] intValues = new int[width * width];
        for (int k = 0; k < testBmp.length; k++) {
            Bitmap bmp = testBmp[k];
            for (int i = 0; i < corps; i++) {
                ByteBuffer imgData = ByteBuffer.allocateDirect(1 * width * width * 3 * BYTES_PER_CHANNEL);
                imgData.order(ByteOrder.nativeOrder());

                if (bmp.getWidth() > bmp.getHeight()) {
                    //get the ARGB pixels
                    bmp.getPixels(intValues, 0, width, i * offsetStep, 0, width, width);
                } else {
                    bmp.getPixels(intValues, 0, width, 0, i * offsetStep, width, width);
                }
                int pixel = 0;
                for (int x = 0; x < width; ++x) {
                    for (int y = 0; y < width; ++y) {
                        int pixelValue = intValues[pixel++];
                        imgData.putFloat((pixelValue >> 16) & 0xFF);//R
                        imgData.putFloat((pixelValue >> 8) & 0xFF); //G
                        imgData.putFloat(pixelValue & 0xFF); //B
                    }
                }
                buffers.add(imgData);
            }
        }
        return buffers;
    }

//    private float[] runModelOnImage(HashMap args) throws IOException {
//        String path = args.get("path").toString();
//        int NUM_THREADS = (int)args.get("numThreads");
//        int WANTED_WIDTH = (int)args.get("inputSize");
//        int WANTED_HEIGHT = (int)args.get("inputSize");
//        int WANTED_CHANNELS = (int)args.get("numChannels");
//        double mean = (double)(args.get("imageMean"));
//        float IMAGE_MEAN = (float)mean;
//        double std = (double)(args.get("imageStd"));
//        float IMAGE_STD = (float)std;
//        int NUM_RESULTS = (int)args.get("numResults");
//        double threshold = (double)args.get("threshold");
//        float THRESHOLD = (float)threshold;
//
//        //ByteBuffer imgData = loadImage(path, WANTED_WIDTH, WANTED_HEIGHT, WANTED_CHANNELS, IMAGE_MEAN, IMAGE_STD);
//        Log.e("tflite", "load image2");
//        Log.e(TAG, String.format("%s %d", path, new File(path).length()));
//        InputStream inputStream = new FileInputStream(path.replace("file://",""));
//        Bitmap bitmapRaw = BitmapFactory.decodeStream(inputStream);
//        List<ByteBuffer> buffers = loadImage(bitmapRaw, WANTED_WIDTH, 3, path);
//        Log.e("tflite", String.format("load image2 ok. buffer len:%d", buffers.size()));
//
//        tfLite.setNumThreads(NUM_THREADS);
//
////        Map<Integer, Object> predFeatures = new HashMap();
////        for (int i = 0; i < buffers.size(); i++) {
////            predFeatures.put(i, new float[1][CLASS_NUM]);
////        }
////        tfLite.runForMultipleInputsOutputs(buffers.toArray(), predFeatures);
//
//        float[] weights = {0.3f, 0.4f, 0.3f};
//        float[] composeFeature = new float[CLASS_NUM];
//        float[][] feature = new float[1][CLASS_NUM];
//        for (int i = 0; i < buffers.size(); i++) {
//            tfLite.run(buffers.get(i), feature);
//            //float[][] feature = (float[][])predFeatures.get(i);
//            for (int j = 0; j < CLASS_NUM; j++) {
//                composeFeature[j] += weights[i] * feature[0][j];
//            }
//        }
//
//        return composeFeature;
//    }

    class ScoreEntry {
        double score;
        int index;

        public ScoreEntry(double score, int index) {
            this.score = score;
            this.index = index;
        }
    }

    private ByteBuffer runModelOnImage(HashMap args) throws IOException {
        List<byte[]> bytesList = args.containsKey("bytesList") ? (ArrayList) args.get("bytesList") : null;
        String path = args.containsKey("path") ? args.get("path").toString() : null;

        int imageWidth = args.containsKey("imageWidth") ? (int)args.get("imageWidth") : 0;
        int imageHeight = args.containsKey("imageHeight") ? (int)args.get("imageHeight") : 0;
        int rotation = args.containsKey("rotation") ? (int)args.get("rotation") : 0;
        int NUM_THREADS = (int)args.get("numThreads");
        int WANTED_WIDTH = (int)args.get("inputSize");
        int WANTED_HEIGHT = (int)args.get("inputSize");
        int WANTED_CHANNELS = (int)args.get("numChannels");
        double mean = (double)(args.get("imageMean"));
        float IMAGE_MEAN = (float)mean;
        double std = (double)(args.get("imageStd"));
        float IMAGE_STD = (float)std;
        int NUM_RESULTS = (int)args.get("numResults");
        double threshold = (double)args.get("threshold");
        int k = (int)args.get("k");
        float THRESHOLD = (float)threshold;


        List<ByteBuffer> buffers = null;

        if (bytesList != null) {
            //ByteBuffer imgData = loadImage(path, WANTED_WIDTH, WANTED_HEIGHT, WANTED_CHANNELS, IMAGE_MEAN, IMAGE_STD);
            Log.e("tflite", "load image2");
            ByteBuffer Y = ByteBuffer.wrap(bytesList.get(0));
            ByteBuffer U = ByteBuffer.wrap(bytesList.get(1));
            ByteBuffer V = ByteBuffer.wrap(bytesList.get(2));

            int Yb = Y.remaining();
            int Ub = U.remaining();
            int Vb = V.remaining();

            byte[] data = new byte[Yb + Ub + Vb];

            Y.get(data, 0, Yb);
            V.get(data, Yb, Vb);
            U.get(data, Yb + Vb, Ub);

            Bitmap bitmapRaw = Bitmap.createBitmap(imageWidth, imageHeight, Bitmap.Config.ARGB_8888);
            Allocation bmData = renderScriptNV21ToRGBA888(
                    mRegistrar.context(),
                    imageWidth,
                    imageHeight,
                    data);
            bmData.copyTo(bitmapRaw);

            Matrix matrix = new Matrix();
            matrix.postRotate(rotation);
            bitmapRaw = Bitmap.createBitmap(bitmapRaw, 0, 0, bitmapRaw.getWidth(), bitmapRaw.getHeight(), matrix, true);

            buffers = loadImage(bitmapRaw, WANTED_WIDTH, 3, null);
            Log.e("tflite", String.format("load image2 ok. buffer len:%d", buffers.size()));
        } else if (path != null && path.length() > 0){
            InputStream inputStream = new FileInputStream(path.replace("file://",""));
            Bitmap bitmapRaw = BitmapFactory.decodeStream(inputStream);
            buffers = loadImage(bitmapRaw, WANTED_WIDTH, 3, null);
        }

        tfLite.setNumThreads(NUM_THREADS);

//        Map<Integer, Object> predFeatures = new HashMap();
//        for (int i = 0; i < buffers.size(); i++) {
//            predFeatures.put(i, new float[1][CLASS_NUM]);
//        }
//        tfLite.runForMultipleInputsOutputs(buffers.toArray(), predFeatures);

        float[] weights = {0.3f, 0.4f, 0.3f};
        int dim = 512;
        double[] composeFeature = new double[dim];
        float[][] feature = new float[1][dim];
        for (int i = 0; i < buffers.size(); i++) {
            tfLite.run(buffers.get(i), feature);
            //float[][] feature = (float[][])predFeatures.get(i);
            //Log.e(TAG, String.format("feature len:%d", feature[0].length));
            for (int j = 0; j < dim; j++) {
                composeFeature[j] += weights[i] * feature[0][j];
            }
        }

        if (predFeatures.size() > 0) {
            //在手机端做匹配， 然后返回topK的匹配
            ScoreEntry[] topK = new ScoreEntry[k];
            for (int i = 0; i < k; i++) {
                topK[i] = new ScoreEntry(0, 0);
            }

            double featureNorm = norm(composeFeature);
            for (int i = 0; i < predFeatures.size(); i++) {
                FeatureEntry item = predFeatures.get(i);
                double score = 0;
                for (int j = 0; j < dim; j++) {
                    score += composeFeature[j] * item.features[j];
                }
                score = score / (featureNorm * item.featureNorm);
//            if (i == 2117) {
//                Log.e(TAG, String.format("index:%d, score:%f", i, score));
//            }

                for (int j = k - 1; j >= 0; j--) {
                    if (j == 0 && score > topK[0].score) {
                        for (int n = k - 1; n > 0; n--) {
                            topK[n] = topK[n - 1];
                        }
                        topK[0] = new ScoreEntry(score, item.artId);
                    } else if (j > 0 && score > topK[j].score && score < topK[j - 1].score) {
                        for (int n = k - 1; n > j; n--) {
                            topK[n] = topK[n - 1];
                        }
                        topK[j] = new ScoreEntry(score, item.artId);
                        break;
                    }
                }
            }

            List<ScoreEntry> array = new ArrayList<>();
            for (int i = 0; i < k; i++) {
                if (topK[i].score >= threshold) {
                    array.add(topK[i]);
                }
            }

            ByteBuffer buf = ByteBuffer.allocate(array.size() * 8 + 4).order(ByteOrder.LITTLE_ENDIAN);
            buf.putFloat((float)array.size());
            for (int i = 0; i < array.size(); i++) {
                buf.putFloat((float) array.get(i).index);
                buf.putFloat((float)array.get(i).score);
            }
            return buf;
        } else {
            //直接返回计算出来的feature
            ByteBuffer buf = ByteBuffer.allocate(4 + composeFeature.length * 4).order(ByteOrder.LITTLE_ENDIAN);
            buf.putFloat(-1.0f);
            for (int i = 0; i < composeFeature.length; i++) {
                buf.putFloat((float)composeFeature[i]);
            }
            return buf;
        }
    }




    private float[] runModelOnBinary(HashMap args) throws IOException {
        byte[] binary = (byte[])args.get("binary");
        int NUM_THREADS = (int)args.get("numThreads");
        int NUM_RESULTS = (int)args.get("numResults");
        double threshold = (double)args.get("threshold");
        float THRESHOLD = (float)threshold;

        ByteBuffer imgData = ByteBuffer.wrap(binary);
        tfLite.setNumThreads(NUM_THREADS);
        float[][] feature = new float[1][CLASS_NUM];
        tfLite.run(imgData, feature);
        return feature[0];
    }

    private void close() {
        tfLite.close();
        labelProb = null;
    }

    public static Matrix getTransformationMatrix(final int srcWidth,
                                                 final int srcHeight,
                                                 final int dstWidth,
                                                 final int dstHeight,
                                                 final boolean maintainAspectRatio)
    {
        final Matrix matrix = new Matrix();

        if (srcWidth != dstWidth || srcHeight != dstHeight) {
            final float scaleFactorX = dstWidth / (float) srcWidth;
            final float scaleFactorY = dstHeight / (float) srcHeight;

            if (maintainAspectRatio) {
                final float scaleFactor = Math.max(scaleFactorX, scaleFactorY);
                matrix.postScale(scaleFactor, scaleFactor);
            } else {
                matrix.postScale(scaleFactorX, scaleFactorY);
            }
        }

        matrix.invert(new Matrix());
        return matrix;
    }


    @TargetApi(Build.VERSION_CODES.ECLAIR)
    private void copyExif(String filePathOri, String filePathDest) {
        try {
            ExifInterface oldExif = new ExifInterface(filePathOri);
            ExifInterface newExif = new ExifInterface(filePathDest);

            List<String> attributes =
                    Arrays.asList(
                            "FNumber",
                            "ExposureTime",
                            "ISOSpeedRatings",
                            "GPSAltitude",
                            "GPSAltitudeRef",
                            "FocalLength",
                            "GPSDateStamp",
                            "WhiteBalance",
                            "GPSProcessingMethod",
                            "GPSTimeStamp",
                            "DateTime",
                            "Flash",
                            "GPSLatitude",
                            "GPSLatitudeRef",
                            "GPSLongitude",
                            "GPSLongitudeRef",
                            ExifInterface.TAG_GPS_ALTITUDE,
                            ExifInterface.TAG_GPS_ALTITUDE_REF,
                            "Make",
                            "Model",
                            "Orientation");
            for (String attribute : attributes) {
                if (oldExif.getAttribute(attribute) != null) {
                    newExif.setAttribute(attribute, oldExif.getAttribute(attribute));
                }
            }
            newExif.saveAttributes();

        } catch (Exception ex) {
            Log.e(TAG, "Error preserving Exif data on selected image: " + ex);
        }
    }
}