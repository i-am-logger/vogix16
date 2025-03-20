# Vogix16

> Functional colors for minimalist minds.

A minimalist design system that focuses on functional color usage. Vogix16 uses a carefully defined color palette where colors are primarily reserved for functional elements like status indicators, interactive controls, and system states.

## What is Vogix16?

Vogix16 is both a design system and a runtime theme management system specifically designed for NixOS:

- **Design System**: A minimalist approach to UI colors that assigns functional meaning to each color in the palette. [Learn more about the design system →](docs/design-system.md)
- **Runtime Theme Management**: A complete system for switching themes dynamically without requiring NixOS rebuilds
- **Practical Implementation**: Combines design principles with technical implementation for a cohesive experience

While inspired by Base16, Vogix16 places greater emphasis on semantic color meaning and provides runtime tools to make theme switching seamless across the entire desktop environment. See the [architecture overview](docs/architecture.md) for details on directory structure and theme processing implementation, and [CLI documentation](docs/cli.md) for usage instructions.

## Philosophy

Vogix follows a "less is more" approach to design:

- Colors are used intentionally and only where they provide functional value
- Interface surfaces use a monochromatic color scale (which may be any color family, not just gray)
- True distinct colors are reserved for elements that benefit from clear visual distinction
- Dark and light variants maintain the same semantic color meanings

## Theme Examples

Vogix16 includes a variety of themes that demonstrate its flexible design system:

<img src="./assets/vogix16_aikido.svg" width="50%" alt="Vogix16 Aikido Theme Example">

**[Browse the full theme catalog →](./themes/README.md)**

Themes range from natural-inspired palettes to modern and vintage aesthetics, all while maintaining consistent functional color meanings regardless of the specific colors used. Check out our [theme format documentation](docs/theming.md) for creating and customizing themes, and the [reload mechanism documentation](docs/reload.md) for dynamic theme application.

## License

Creative Commons Attribution-NonCommercial-ShareAlike (CC BY-NC-SA)

This work is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/).

