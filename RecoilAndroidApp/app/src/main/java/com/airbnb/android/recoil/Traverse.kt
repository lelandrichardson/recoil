package com.airbnb.android.recoil


private val SEPARATOR = "."
private val SUBSEPARATOR = ":"

typealias TraversalCallback<T> = (T, Element, String) -> Unit

private fun getKey(el: Element?, index: Int): String {
  // This is where we would use the key prop to generate a unique id that
  // persists across moves. However we're skipping that so we'll just use the
  // index.
  if (el?.key != null) {
    return el.key.toString()
  }
  return "$index"
}

private fun <T> traverseAllChildrenImpl(
  children: Element?,
  nameSoFar: String,
  traverseContext: T,
  callback: TraversalCallback<T>
): Int {
  // TODO: support booleans
  if (children == null) {
    return 0
  }

  when (children.tag) {
    Tag.Array -> {
      val elements = children.props as? List<*> ?: throw IllegalStateException("")
      // Otherwise we have an array. React also supports iterators but we won't.
      // We need to return the number of children so start tracking that.
      // Note that this isn't simply children.length - since children can contain nested
      // arrays, we need to account for that too, as those are rendered at the same level.
      var subTreeCount = 0
      val nextNamePrefix = if (nameSoFar == "") SEPARATOR else nameSoFar + SUBSEPARATOR

      // Loop over all children, generate the next key prefix, and then recurse!
      for (i in 0 until elements.count()) {
        val child = elements[i] as? Element? ?: throw IllegalStateException("")
        val nextName = nextNamePrefix + getKey(child, i)
        subTreeCount += traverseAllChildrenImpl(
          child,
          nextName,
          traverseContext,
          callback
        )
      }

      return subTreeCount
    }
    else -> {
      callback(traverseContext, children, nameSoFar + SEPARATOR + getKey(children, 0))
      return 1
    }
  }
}

fun <T> traverseAllChildren(
  children: Element?,
  traverseContext: T,
  callback: TraversalCallback<T>
): Int {
  return traverseAllChildrenImpl(children, "", traverseContext, callback)
}
