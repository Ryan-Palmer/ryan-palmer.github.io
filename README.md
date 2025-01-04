# GH Pages Blog powered by Jekyll

## Development

You will need Docker installed to run the devcontainer for local editing.

Hit `Ctrl-Shift-P` to open the command pallet and select `Dev Containers: Reopen in Container`.

The first time you do this it will need to build the container so will take a minute, but subsequently it should open almost immediately.

After starting the container, run
```bash
bundle exec jekyll serve --livereload
```

You can visit the running site at `http://127.0.0.1:4000/`. Any changes to the site files should cause a rebuild / browser refresh. 

> Edits to blog posts don't trigger this, so just re-save a root file to trigger the rebuild.

To exit the container, hit `Ctrl-Shift-P` again and select `Dev Containers: Reopen Folder Locally`.

## Deployment

Pushing to `main` will publish the site.