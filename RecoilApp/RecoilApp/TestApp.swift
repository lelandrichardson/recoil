

import Recoil

struct ButtonProps {
  let title: String
  let onPress: () -> ()
}

//class Button: Component<ButtonProps> {
//  override func render() -> Element? {
//    return (
//      h(View.self, ViewProps()
//          .onPress(props.onPress)
//      ) {
//        h(props.title)
//      }
//    )
//  }
//}

enum MeasureMode {
  case exact
  case atMost
  case undefined
}

struct LayoutInfo {
  let width: Float
  let widthMode: MeasureMode
  let height: Float
  let heightMode: MeasureMode
}

class Button: LayoutAwareComponent<ButtonProps> {
  override func render(layout: LayoutInfo) -> Element? {
    // ...
  }
}

