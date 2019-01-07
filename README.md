# dropbox-universal-backup-tool

![screenshot](https://user-images.githubusercontent.com/1631752/50747659-db092900-1213-11e9-9806-485ef5a7ab82.png)

A command line tool for doing unidirectional syncs with Dropbox folders. 

## Purpose

This command line tool was created for the people who do regular backups on Dropbox.

The official client has some drawbacks:

* It **forces you** to put all your files inside the `Dropbox` directory
* It gives you almost **no control** of what is being uploaded or not
* It does **bidireccional synchronization**, which could be dangerous and avoidable if your only purpose is backupping your files

## Install

- Clone the repo
- Create a link in `/usr/local/bin/dxubt` pointing to `dxubt.js`
- Run `dxubt --help` to see common usages
