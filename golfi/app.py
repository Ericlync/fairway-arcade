"""Minimal Ursina application and placeholder golf scene."""

from pathlib import Path

import ursina
from ursina import Entity, Ursina, camera, color, window


def main() -> None:
    """Open the initial game window and render a simple course view."""
    app = Ursina(
        title="Fairway Arcade",
        icon=str(Path(ursina.__file__).parent / "textures" / "ursina.ico"),
        fullscreen=False,
        size=(1280, 720),
        development_mode=False,
        editor_ui_enabled=False,
    )
    window.color = color.rgb(125, 185, 220)

    # Ursina's plane lies in the XZ ground plane. These placeholder meshes do
    # not need custom shaders; gameplay systems will be added in later
    # milestones without coupling them to application startup.
    Entity(
        model="plane",
        scale=(100, 1, 100),
        color=color.rgb(75, 145, 65),
        shader=None,
    )
    Entity(
        model="plane",
        position=(0, 0.01, 9),
        scale=(18, 1, 48),
        color=color.rgb(105, 175, 75),
        shader=None,
    )
    Entity(
        model="sphere",
        position=(0, 0.04, 28),
        scale=(0.8, 0.08, 0.8),
        color=color.rgb(30, 35, 30),
        shader=None,
    )
    Entity(
        model="sphere",
        position=(0, 0.55, -15),
        scale=0.7,
        color=color.white,
        shader=None,
    )

    camera.position = (0, 26, -34)
    camera.look_at((0, 0, 7))

    app.run()
