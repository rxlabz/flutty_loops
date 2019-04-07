package bz.rxla.flutty_loops;

import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {

  private static final String CHANNEL = "bz.rxla/tone";

  private double mInterval = 0.125;
  private int mSampleRate = 8000;

  private Map<Integer, AudioTrack> trackMap = new HashMap<Integer, AudioTrack>();

  private final double mStandardFreq = 440;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
            new MethodChannel.MethodCallHandler() {
              @Override
              public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                if (call.method.equals("play")) {
                  if (((ArrayList<Integer>) call.arguments).size() > 0) {
                    for (Iterator<Integer> i = ((ArrayList<Integer>) call.arguments).iterator(); i.hasNext(); ) {
                      bip(i.next());
                    }
                  }
                }
              }
            });
  }

  private void bip(Integer id) {
    final Thread thread = new Thread(new Runnable() {
      public void run() {
        byte[] tempByte = new byte[0];double note = getNoteFrequencies(id);
        byte[] tonByteNote = getTone(mInterval, mSampleRate, note);
        tempByte = concat(tonByteNote, tempByte);
        byte[] generatedSnd = tempByte;

        playTrack(id, generatedSnd);
      }
    });
    thread.start();
  }

  public byte[] concat(byte[] a, byte[] b) {
    int aLen = a.length;
    int bLen = b.length;
    byte[] c = new byte[aLen + bLen];
    System.arraycopy(a, 0, c, 0, aLen);
    System.arraycopy(b, 0, c, aLen, bLen);
    return c;
  }

  private double getNoteFrequencies(int index) {
    return mStandardFreq * Math.pow(2, (double) index / 12.0d);
  }

  private byte[] getTone(double duration, int rate, double frequencies) {

    double dnumSamples = duration * rate;
    dnumSamples = Math.ceil(dnumSamples);
    int numSamples = (int) dnumSamples;
    double sample[] = new double[numSamples];
    byte generatedSnd[] = new byte[2 * numSamples];


    for (int i = 0; i < numSamples; ++i) {
      sample[i] = sine(i, frequencies / rate);
    }
    int idx = 0;
    int i = 0;

    int ramp = numSamples / 20;


    for (i = 0; i < ramp; ++i) {
      double dVal = sample[i];
      final short val = (short) ((dVal * 32767 * i / ramp));
      generatedSnd[idx++] = (byte) (val & 0x00ff);
      generatedSnd[idx++] = (byte) ((val & 0xff00) >>> 8);
    }

    for (i = i; i < numSamples - ramp; ++i) {
      double dVal = sample[i];
      final short val = (short) ((dVal * 32767));
      generatedSnd[idx++] = (byte) (val & 0x00ff);
      generatedSnd[idx++] = (byte) ((val & 0xff00) >>> 8);
    }

    for (i = i; i < numSamples; ++i) {
      double dVal = sample[i];
      final short val = (short) ((dVal * 32767 * (numSamples - i) / ramp));
      generatedSnd[idx++] = (byte) (val & 0x00ff);
      generatedSnd[idx++] = (byte) ((val & 0xff00) >>> 8);
    }
    return generatedSnd;
  }

  private AudioTrack getAudioTrack(Integer id, int length) {

    if (trackMap.containsKey(id)) {
      final AudioTrack track = trackMap.get(id);
      track.stop();
      return track;
    }

    final AudioTrack track = new AudioTrack(AudioManager.STREAM_MUSIC,
            mSampleRate, AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT, length,
            AudioTrack.MODE_STREAM, id);
    trackMap.put(id, track);

    return track;
  }

  private double sine(int x, double frequencies) {
    return Math.sin(2 * Math.PI * x * frequencies);
  }

  void playTrack(Integer id, byte[] generatedSnd) {
    AudioTrack track = getAudioTrack(id, generatedSnd.length);
    track.write(generatedSnd, 0, generatedSnd.length);
    try {
      track.play();
    } catch (Error err) {
      Log.e("RX", "AUDIO TRACK ERROR : " + err.toString());
    }
  }
}
