<a href="https://pub.dev/packages/slide_action"><img src="https://img.shields.io/badge/pub-0.0.1+2-green" alt="pub.dev"></a>
[![likes](https://badges.bar/slide_action/likes)](https://pub.dev/packages/slide_action/score)
[![popularity](https://badges.bar/slide_action/popularity)](https://pub.dev/packages/slide_action/score)
[![pub points](https://badges.bar/slide_action/pub%20points)](https://pub.dev/packages/slide_action/score)
<a href="https://pub.dev/packages/slide_action"><img src="https://img.shields.io/badge/license-MIT-yellow" alt="pub.dev"></a>

# ➡️ Slide Action

**Slide action** is a simple to use widget where the user has to *slide to perform an action*.

<br>

## Example Preview 📱

![Slide action preview](https://raw.githubusercontent.com/kay-af/slide-action/main/preview_assets/example.gif)

<br>

## Features

* Highly customizable.
* Smooth thumb movement.
* RTL support.
* Async operations support.
* Multi-platform support.
* Multiple examples (included in *example* project)

<br>

## Installing

Add this line to your `pubspec.yaml` under the dependencies:

```yaml
dependencies:
  slide_action: ^0.0.1+2
```

alternatively, you can use this command:

```
flutter pub add slide_action
```

<br>

## Usage

Simple Example

```dart
SlideAction(
    trackBuilder: (context, state) {
        return Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                    ),
                ],
            ),
            child: Center(
                child: Text(
                    "Thumb fraction: ${state.thumbFractionalPosition.toStringAsPrecision(2)}",
                ),
            ),
        );
    },
    thumbBuilder: (context, state) {
        return Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
                child: Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                ),
            ),
        );
    },
    action: () {
        debugPrint("Hello World");
    },
);
```

<br>

![SlideAction Simple Example 1](https://raw.githubusercontent.com/kay-af/slide-action/main/preview_assets/quick-example-1.gif)

<br>

### Async Example

```dart
SlideAction(
    trackBuilder: (context, state) {
        return Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                    ),
                ],
            ),
            child: Center(
                child: Text(
                    // Show loading if async operation is being performed
                    state.isPerformingAction
                        ? "Loading..."
                        : "Thumb fraction: ${state.thumbFractionalPosition.toStringAsPrecision(2)}",
                ),
            ),
        );
    },
    thumbBuilder: (context, state) {
        return Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
                // Show loading indicator if async operation is being performed
                child: state.isPerformingAction
                    ? const CupertinoActivityIndicator(
                        color: Colors.white,
                    )
                    : const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                    ),
            ),
        );
    },
    action: () async {
        // Async operation
        await Future.delayed(
            const Duration(seconds: 2),
            () => debugPrint("Hello World"),
        );
    },
);
```

<br>

![SlideAction Simple Example 2](https://raw.githubusercontent.com/kay-af/slide-action/main/preview_assets/quick-example-2.gif)

<br>

## Additional information

Check the <a href="https://pub.dev/documentation/slide_action/latest/">documentation</a> or <a href="https://github.com/kay-af/slide-action/tree/main/example">example project</a> on github for advanced usage.

Facing issues? Feel free to <a href="https://github.com/kay-af/slide-action/issues">report an issue</a> on the <a href="https://github.com/kay-af/slide-action">Github Page</a>