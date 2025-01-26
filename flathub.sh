#!/usr/bin/env bash

dnf install flatpak -y
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y org.localsend.localsend_app io.github.seadve.Kooha dev.skynomads.Seabird

