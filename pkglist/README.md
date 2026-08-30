# Package manifests

`official.txt` and `aur.txt` contain explicitly installed packages. The pacman
hook refreshes both manifests after package transactions without contacting the
network.

## Restore

Install repository packages first:

```bash
sudo pacman -S --needed - < pkglist/official.txt
```

Then install AUR packages with `paru`:

```bash
paru -S --needed - < pkglist/aur.txt
```

## Refresh manually

```bash
update-pkglist
```

The updater generates both manifests before replacing either existing file.
