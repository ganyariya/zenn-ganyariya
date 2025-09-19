# Project Overview

This repository is for managing and writing articles for the Zenn online publication. It is a non-code project focused on content creation.

# Key Files

*   `articles/`: This directory contains the markdown files for each article.
*   `package.json`: This file lists the project's dependencies, which are primarily for linting and working with Zenn's command-line tool.
*   `.textlintrc`: This file configures the rules for `textlint`, a tool for linting Japanese text.
*   `Makefile`: This file contains convenient commands for common tasks like creating new articles, previewing them, and running the linter.

# Development Workflow

## Setup

To get started, install the necessary dependencies:

```bash
npm install
```

## Writing and Previewing

1.  To create a new article, use the following command, replacing `your-slug-here` with the desired URL slug for your article:

    ```bash
    make article SLUG=your-slug-here
    ```

2.  To preview your articles locally, run:

    ```bash
    npx zenn preview
    ```

    This will start a local server, and you can view your articles in a web browser.

## Linting

This project uses `textlint` to enforce a consistent writing style.

*   To check for linting errors, run:

    ```bash
    make lint
    ```

*   To automatically fix some linting errors, run:

    ```bash
    make fix-lint
    ```
