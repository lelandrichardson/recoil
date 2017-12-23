package com.airbnb.android.recoil

import android.content.Context
import android.view.View
import android.widget.ImageView
import com.facebook.yoga.YogaNode
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.AsyncTask



class ImageHostView(context: Context): ImageView(context), RecoilView {
  override var yogaNode = YogaNode()
  override fun getHostView(): View = this
  override fun getYogaNodeForView(view: View): YogaNode? = null
  override fun getRecoilSubviewAt(index: Int): RecoilView? = null
  override fun insertRecoilSubview(view: RecoilView, index: Int) {}
  override fun moveRecoilSubview(fromIndex: Int, toIndex: Int) {}
  override fun removeRecoilSubview(fromIndex: Int) {}
  override fun getRecoilParent(): RecoilView? = parent as? RecoilView

  init {
    yogaNode.data = this
    yogaNode.setMeasureFunction(ViewMeasureFunction())
  }

  var onPress: (() -> Unit)? = null
  var source: ImageSource? = null
    get() = field
    set(value) {
      field = value
      if (value?.uri != null) {
        DownloadImageTask(this).execute(value.uri)
      }
    }
}


private class DownloadImageTask(
    internal var imageView: ImageView
): AsyncTask<String, Void, Bitmap?>() {

  override fun doInBackground(vararg url: String): Bitmap? {
    return try {
      val inputStream = java.net.URL(url[0]).openStream()
      BitmapFactory.decodeStream(inputStream)
    } catch (e: Exception) {
      e.printStackTrace()
      null
    }
  }

  override fun onPostExecute(result: Bitmap?) {
    if (result != null) {
      imageView.setImageBitmap(result)
    }
  }
}
