# Project Requirements Document (PRD)

The application is a web based drawing app.
It has a canvas where users can draw using various tools and colors.

## Scope

MVP : drawing mode with some of the tools
- Pen, Circle, Rectangle, Line tool
- Eraser tool
- Color picker
- Undo/Redo functionality
- Save/Load drawings


## Screens
- Home Screen
  - Welcome message
  - Start Drawing button
  - Instructions/Help section
  - scaffold background : @assets/images/muhammad-rahim-ali-NRBBze-P0Sc-unsplash.jpg image
  
- Drawing Screen
  - Canvas area
  - Tool selection panel as a Floating Action button: brush, circle, rectangle, line, eraser
  - Color picker always visible on the bottom
  - on the top right of the screen, in the AppBar actions: Undo/Redo, Save/Load buttons

## Navigation
- From Home Screen to Drawing Screen via Start Drawing button
- From Drawing Screen back to Home Screen via back arrow button in the AppBar
- Open the Instructions/Help in a modal dialog from the Home Screen


## Theming

Use the FlexColorScheme for theming
- use the "Deep purple color" scheme
- Light and Dark mode support
- Consistent color scheme across the app
- Customizable primary, secondary, and background colors
- 

