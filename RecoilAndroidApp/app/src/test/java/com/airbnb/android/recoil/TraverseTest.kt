package com.airbnb.android.recoil

import org.junit.Assert.assertEquals
import org.junit.Test

class TraverseTest {

  private class LeafProps
  private class Leaf(override var props: LeafProps) : Component<LeafProps, Unit>(props) {
    override fun getInitialState() = Unit
    override fun render(): Element? = null
  }

  private fun leaf(key: Key? = null): Element = Element(Leaf::class, LeafProps(), key)

  private fun array(vararg children: Element): Element =
    Element(Tag.Array, Array<Element>::class, children.toList(), null)

  private fun visit(root: Element?): List<String> {
    val names = mutableListOf<String>()
    val count = traverseAllChildren(root, names) { ctx, _, name -> ctx.add(name) }
    assertEquals(count, names.size)
    return names
  }

  @Test
  fun traverse_nullRoot_visitsNothing() {
    assertEquals(emptyList<String>(), visit(null))
  }

  @Test
  fun traverse_singleChild_usesIndexZero() {
    assertEquals(listOf(".0"), visit(leaf()))
  }

  @Test
  fun traverse_singleChildWithKey_usesThatKey() {
    assertEquals(listOf(".hello"), visit(leaf("hello")))
  }

  @Test
  fun traverse_flatArray_usesIndexBasedKeys() {
    val names = visit(array(leaf(), leaf(), leaf()))
    assertEquals(listOf(".0.0", ".1.0", ".2.0"), names)
  }

  @Test
  fun traverse_keyedArray_preservesKeys() {
    val names = visit(array(leaf("a"), leaf("b"), leaf("c")))
    assertEquals(listOf(".a.a", ".b.b", ".c.c"), names)
  }

  @Test
  fun traverse_nestedArray_usesSubseparatorForDepth() {
    val nested = array(leaf("a"), array(leaf("b"), leaf("c")), leaf("d"))
    val names = visit(nested)
    assertEquals(listOf(".a.a", ".1:b.b", ".1:c.c", ".d.d"), names)
  }
}
