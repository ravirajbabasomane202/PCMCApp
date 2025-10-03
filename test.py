import sys
import cv2
import numpy as np
import mss
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                            QHBoxLayout, QPushButton, QComboBox, QLabel, 
                            QSpinBox, QSystemTrayIcon, QMenu, QDialog)
from PyQt6.QtCore import QThread, pyqtSignal, Qt, QPoint
from PyQt6.QtGui import QIcon, QAction, QPainter, QColor, QFont, QPalette
from PyQt6.QtWidgets import QMessageBox

class CaptureThread(QThread):
    update_frame = pyqtSignal(np.ndarray)
    error_signal = pyqtSignal(str)

    def __init__(self, monitor_index=1, box_width=200, box_height=150, output_width=1280, output_height=720):
        super().__init__()
        self.monitor_index = monitor_index
        self.box_width = box_width
        self.box_height = box_height
        self.output_width = output_width
        self.output_height = output_height
        self.running = False

    def run(self):
        try:
            with mss.mss() as sct:
                while self.running:
                    if self.monitor_index >= len(sct.monitors):
                        self.error_signal.emit(f"Monitor {self.monitor_index} not available")
                        break
                    
                    monitor = sct.monitors[self.monitor_index]
                    img = np.array(sct.grab(monitor))
                    frame = cv2.cvtColor(img, cv2.COLOR_BGRA2BGR)

                    h, w, _ = frame.shape
                    cx, cy = w // 2, h // 2
                    x1, y1 = cx - self.box_width // 2, cy - self.box_height // 2
                    x2, y2 = cx + self.box_width // 2, cy + self.box_height // 2

                    # Ensure coordinates are within bounds
                    x1, y1 = max(0, x1), max(0, y1)
                    x2, y2 = min(w, x2), min(h, y2)

                    cropped = frame[y1:y2, x1:x2]
                    enlarged = cv2.resize(cropped, (self.output_width, self.output_height), 
                                        interpolation=cv2.INTER_LINEAR)
                    
                    self.update_frame.emit(enlarged)
                    
        except Exception as e:
            self.error_signal.emit(str(e))

    def stop(self):
        self.running = False
        self.wait()

class FloatingControls(QMainWindow):
    def __init__(self):
        super().__init__()
        self.capture_thread = None
        self.zoom_window = None
        self.init_ui()
        self.init_tray()
        
        # Default settings
        self.settings = {
            'monitor_index': 1,
            'box_width': 200,
            'box_height': 150,
            'output_width': 1280,
            'output_height': 720
        }

    def init_ui(self):
        self.setWindowTitle("Screen Zoom")
        self.setWindowFlags(Qt.WindowType.FramelessWindowHint | Qt.WindowType.WindowStaysOnTopHint)
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.setFixedSize(80, 80)

        # Central widget with rounded corners
        central_widget = QWidget()
        central_widget.setStyleSheet("""
            QWidget {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:1,
                    stop:0 #4A90E2, stop:1 #357ABD);
                border-radius: 40px;
                border: 2px solid #2C5F9B;
            }
            QWidget:hover {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:1,
                    stop:0 #5A9FE2, stop:1 #468ACD);
            }
        """)
        
        layout = QVBoxLayout(central_widget)
        layout.setContentsMargins(5, 5, 5, 5)

        # Menu button
        self.menu_btn = QPushButton("☰")
        self.menu_btn.setFont(QFont("Arial", 16, QFont.Weight.Bold))
        self.menu_btn.setStyleSheet("""
            QPushButton {
                background: transparent;
                border: none;
                color: white;
                font-weight: bold;
            }
            QPushButton:hover {
                color: #E6F3FF;
            }
        """)
        self.menu_btn.clicked.connect(self.show_control_panel)
        layout.addWidget(self.menu_btn)

        self.setCentralWidget(central_widget)

        # Make window draggable
        self.dragging = False
        self.offset = QPoint()

    def mousePressEvent(self, event):
        if event.button() == Qt.MouseButton.LeftButton:
            self.dragging = True
            self.offset = event.pos()

    def mouseMoveEvent(self, event):
        if self.dragging:
            self.move(self.pos() + event.pos() - self.offset)

    def mouseReleaseEvent(self, event):
        self.dragging = False

    def init_tray(self):
        self.tray_icon = QSystemTrayIcon(self)
        self.tray_icon.setIcon(self.style().standardIcon(self.style().StandardPixmap.SP_ComputerIcon))
        
        tray_menu = QMenu()
        
        show_action = QAction("Show Controls", self)
        show_action.triggered.connect(self.show)
        
        quit_action = QAction("Exit", self)
        quit_action.triggered.connect(self.quit_application)
        
        tray_menu.addAction(show_action)
        tray_menu.addAction(quit_action)
        
        self.tray_icon.setContextMenu(tray_menu)
        self.tray_icon.activated.connect(self.tray_icon_activated)
        self.tray_icon.show()

    def tray_icon_activated(self, reason):
        if reason == QSystemTrayIcon.ActivationReason.DoubleClick:
            self.show()

    def show_control_panel(self):
        if hasattr(self, 'control_panel') and self.control_panel.isVisible():
            self.control_panel.close()
            return

        self.control_panel = ControlPanel(self)
        self.control_panel.show()
        # Position control panel next to main window
        pos = self.pos()
        self.control_panel.move(pos.x() + self.width() + 5, pos.y())

    def start_capture(self):
        if self.capture_thread and self.capture_thread.isRunning():
            return

        self.capture_thread = CaptureThread(
            self.settings['monitor_index'],
            self.settings['box_width'],
            self.settings['box_height'],
            self.settings['output_width'],
            self.settings['output_height']
        )
        self.capture_thread.update_frame.connect(self.show_zoom_window)
        self.capture_thread.error_signal.connect(self.show_error)
        self.capture_thread.running = True
        self.capture_thread.start()

    def stop_capture(self):
        if self.capture_thread:
            self.capture_thread.stop()
        if self.zoom_window:
            self.zoom_window.close()
            self.zoom_window = None

    def show_zoom_window(self, frame):
        if not hasattr(self, 'zoom_window') or not self.zoom_window:
            self.zoom_window = ZoomWindow()
        self.zoom_window.update_frame(frame)

    def show_error(self, error_msg):
        QMessageBox.critical(self, "Error", f"Capture error: {error_msg}")

    def closeEvent(self, event):
        self.stop_capture()
        event.accept()

    def quit_application(self):
        self.stop_capture()
        QApplication.quit()

class ZoomWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Zoomed View - Press Q to close")
        self.setWindowFlags(Qt.WindowType.WindowStaysOnTopHint)
        self.setGeometry(100, 100, 1280, 720)
        
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        self.label = QLabel()
        self.label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        
        layout = QVBoxLayout(central_widget)
        layout.addWidget(self.label)
        
        self.show()

    def update_frame(self, frame):
        # Convert BGR to RGB
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Convert to QImage
        h, w, ch = frame_rgb.shape
        bytes_per_line = ch * w
        qt_image = QImage(frame_rgb.data, w, h, bytes_per_line, QImage.Format.Format_RGB888)
        
        # Scale image to fit label while maintaining aspect ratio
        self.label.setPixmap(QIcon(qt_image).pixmap(self.label.size()))

    def keyPressEvent(self, event):
        if event.key() == Qt.Key.Key_Q:
            self.close()

class ControlPanel(QDialog):
    def __init__(self, parent):
        super().__init__(parent)
        self.parent = parent
        self.init_ui()

    def init_ui(self):
        self.setWindowTitle("Screen Zoom Controls")
        self.setWindowFlags(Qt.WindowType.WindowStaysOnTopHint | Qt.WindowType.Tool)
        self.setFixedSize(300, 400)
        self.setStyleSheet("""
            QDialog {
                background: #2b2b2b;
                color: white;
                border: 1px solid #444;
                border-radius: 10px;
            }
            QLabel {
                color: white;
                font-weight: bold;
                padding: 5px;
            }
            QPushButton {
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
                    stop:0 #5A5A5A, stop:1 #3A3A3A);
                border: 1px solid #555;
                border-radius: 5px;
                color: white;
                padding: 8px;
                font-weight: bold;
            }
            QPushButton:hover {
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
                    stop:0 #6A6A6A, stop:1 #4A4A4A);
            }
            QPushButton:pressed {
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
                    stop:0 #4A4A4A, stop:1 #2A2A2A);
            }
            QSpinBox {
                background: #404040;
                border: 1px solid #555;
                border-radius: 3px;
                color: white;
                padding: 5px;
            }
            QComboBox {
                background: #404040;
                border: 1px solid #555;
                border-radius: 3px;
                color: white;
                padding: 5px;
            }
        """)

        layout = QVBoxLayout()

        # Monitor selection
        layout.addWidget(QLabel("Select Monitor:"))
        self.monitor_combo = QComboBox()
        self.populate_monitors()
        layout.addWidget(self.monitor_combo)

        # Box size controls
        box_layout = QHBoxLayout()
        box_layout.addWidget(QLabel("Box Width:"))
        self.box_width_spin = QSpinBox()
        self.box_width_spin.setRange(50, 1000)
        self.box_width_spin.setValue(self.parent.settings['box_width'])
        box_layout.addWidget(self.box_width_spin)
        
        box_layout.addWidget(QLabel("Box Height:"))
        self.box_height_spin = QSpinBox()
        self.box_height_spin.setRange(50, 1000)
        self.box_height_spin.setValue(self.parent.settings['box_height'])
        box_layout.addWidget(self.box_height_spin)
        layout.addLayout(box_layout)

        # Output size controls
        output_layout = QHBoxLayout()
        output_layout.addWidget(QLabel("Output Width:"))
        self.output_width_spin = QSpinBox()
        self.output_width_spin.setRange(100, 3840)
        self.output_width_spin.setValue(self.parent.settings['output_width'])
        output_layout.addWidget(self.output_width_spin)
        
        output_layout.addWidget(QLabel("Output Height:"))
        self.output_height_spin = QSpinBox()
        self.output_height_spin.setRange(100, 2160)
        self.output_height_spin.setValue(self.parent.settings['output_height'])
        output_layout.addWidget(self.output_height_spin)
        layout.addLayout(output_layout)

        # Control buttons
        self.start_btn = QPushButton("▶ Start Capture")
        self.start_btn.clicked.connect(self.toggle_capture)
        layout.addWidget(self.start_btn)

        settings_btn = QPushButton("⚙ Save Settings")
        settings_btn.clicked.connect(self.save_settings)
        layout.addWidget(settings_btn)

        close_btn = QPushButton("✕ Close")
        close_btn.clicked.connect(self.close)
        layout.addWidget(close_btn)

        self.setLayout(layout)

    def populate_monitors(self):
        try:
            with mss.mss() as sct:
                for i, monitor in enumerate(sct.monitors):
                    self.monitor_combo.addItem(f"Monitor {i} ({monitor['width']}x{monitor['height']})", i)
                self.monitor_combo.setCurrentIndex(self.parent.settings['monitor_index'])
        except Exception as e:
            self.monitor_combo.addItem(f"Monitor 0 - Error: {str(e)}", 0)

    def toggle_capture(self):
        if self.parent.capture_thread and self.parent.capture_thread.isRunning():
            self.parent.stop_capture()
            self.start_btn.setText("▶ Start Capture")
        else:
            self.save_settings()
            self.parent.start_capture()
            self.start_btn.setText("⏹ Stop Capture")

    def save_settings(self):
        self.parent.settings.update({
            'monitor_index': self.monitor_combo.currentIndex(),
            'box_width': self.box_width_spin.value(),
            'box_height': self.box_height_spin.value(),
            'output_width': self.output_width_spin.value(),
            'output_height': self.output_height_spin.value()
        })

def main():
    app = QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)
    
    window = FloatingControls()
    window.show()
    
    sys.exit(app.exec())

if __name__ == "__main__":
    main()