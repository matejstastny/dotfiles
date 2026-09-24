#!/usr/bin/env python3
#@ own a Quick Share image with browser-compatible clipboard formats

import base64
import os
import sys
from pathlib import Path

from PyQt6.QtCore import QByteArray, QMimeData, QTimer, QUrl
from PyQt6.QtGui import QGuiApplication


def main() -> int:
    if len(sys.argv) != 3:
        return 2

    source = Path(sys.argv[1]).resolve()
    pid_file = Path(sys.argv[2])
    png = sys.stdin.buffer.read()
    if not png:
        return 1

    app = QGuiApplication([])
    mime = QMimeData()
    mime.setData("image/png", QByteArray(png))
    mime.setUrls([QUrl.fromLocalFile(str(source))])
    encoded = base64.b64encode(png).decode()
    mime.setHtml(f'<img src="data:image/png;base64,{encoded}">')

    clipboard = app.clipboard()
    clipboard.setMimeData(mime)
    pid_file.parent.mkdir(parents=True, exist_ok=True)
    pid_file.write_text(str(os.getpid()))

    def release_when_replaced() -> None:
        if not clipboard.ownsClipboard():
            app.quit()

    ownership_timer = QTimer()
    ownership_timer.setInterval(1000)
    ownership_timer.timeout.connect(release_when_replaced)
    ownership_timer.start()
    result = app.exec()
    if pid_file.exists() and pid_file.read_text().strip() == str(os.getpid()):
        pid_file.unlink()
    return result


if __name__ == "__main__":
    raise SystemExit(main())
