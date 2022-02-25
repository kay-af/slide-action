# Slide Action

## Overview

A simple yet highly customizable **"Slide To Perform an Action"** widget.

![Slide action widget preview](https://raw.githubusercontent.com/kay-af/slide-action/main/preview_assets/example.gif)

<br>

## Features

* Highly customizable.
* Smooth thumb movement.
* RTL support.
* Async operations support.
* Multi-platform support.
* Multiple examples (included in *example* project)

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

Output:

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

Output:

![SlideAction Simple Example 2](https://raw.githubusercontent.com/kay-af/slide-action/main/preview_assets/quick-example-2.gif)

<br>

## Additional information

Check the **documentation** or **example project** on github for advanced usage.

Facing issues? Feel free to report an issue on the github page.