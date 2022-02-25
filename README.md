# Slide Action

## Overview

A simple yet highly customizable **"Slide To Perform an Action"** widget.

![Slide action widget preview](https://raw.githubusercontent.com/kay-af/slide-action/main/preview_assets/example.gif)

---

## Features

* Highly customizable.
* Smooth thumb movement.
* RTL support.
* Async operations support.
* Multiple examples (included in *example* project)

---

## Usage

Minimal example

```dart
SlideAction(
    trackBuilder: (context, state) {
        // Use the state to customize the track widget.
        return Container(
            color: Colors.grey,
        );
    },
    thumbBuilder: (context, state) {
        // Use the state to customize the thumb widget.
        return Container(
            color: Colors.red,
        );
    },
    action: () {
        debugPrint('Hello World');
    },
);
```

---

## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
