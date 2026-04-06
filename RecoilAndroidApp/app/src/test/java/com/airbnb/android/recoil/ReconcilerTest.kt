package com.airbnb.android.recoil

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ReconcilerTest {

  private class AlphaProps
  private class BetaProps

  private class Alpha(override var props: AlphaProps) : Component<AlphaProps, Unit>(props) {
    override fun getInitialState() = Unit
    override fun render(): Element? = null
  }

  private class Beta(override var props: BetaProps) : Component<BetaProps, Unit>(props) {
    override fun getInitialState() = Unit
    override fun render(): Element? = null
  }

  private fun alpha(key: Key? = null): Element = Element(Alpha::class, AlphaProps(), key)
  private fun beta(key: Key? = null): Element = Element(Beta::class, BetaProps(), key)

  @Test
  fun shouldUpdateComponent_returnsFalse_whenPrevIsNull() {
    assertFalse(Reconciler.shouldUpdateComponent(null, alpha()))
  }

  @Test
  fun shouldUpdateComponent_returnsFalse_whenNextIsNull() {
    assertFalse(Reconciler.shouldUpdateComponent(alpha(), null))
  }

  @Test
  fun shouldUpdateComponent_returnsFalse_whenBothNull() {
    assertFalse(Reconciler.shouldUpdateComponent(null, null))
  }

  @Test
  fun shouldUpdateComponent_returnsTrue_forSameCompositeType() {
    assertTrue(Reconciler.shouldUpdateComponent(alpha(), alpha()))
  }

  @Test
  fun shouldUpdateComponent_returnsFalse_forDifferentCompositeType() {
    assertFalse(Reconciler.shouldUpdateComponent(alpha(), beta()))
  }

  @Test
  fun shouldUpdateComponent_ignoresKeyWhenDecidingReuse() {
    assertTrue(Reconciler.shouldUpdateComponent(alpha("a"), alpha("b")))
  }
}
