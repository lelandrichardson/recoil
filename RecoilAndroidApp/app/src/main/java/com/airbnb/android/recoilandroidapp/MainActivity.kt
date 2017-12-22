package com.airbnb.android.recoilandroidapp

import android.support.v7.app.AppCompatActivity
import android.os.Bundle
import android.view.ViewGroup

import com.airbnb.android.recoil.*
import com.facebook.soloader.SoLoader

class MainActivity: AppCompatActivity() {

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    SoLoader.init(this, false)

    setContentView(R.layout.activity_main)

    val rootView = findViewById(R.id.root) as? ViewGroup ?: throw IllegalStateException()

    val el = h(::App, AppProps(
        foo = "Hello World"
    ))

    Recoil.render(el, rootView)

//    rootView.requestLayout()
  }
}
