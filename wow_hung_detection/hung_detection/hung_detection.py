# coding: utf-8
import win32gui
import win32process
import win32api
import win32con
import ctypes
import time


def get_wow_hwnd():
    return win32gui.FindWindow(0, u"魔兽世界")


def get_wow_process_id(hwnd):
    thread, process = win32process.GetWindowThreadProcessId(hwnd)
    return process


def close_wow(hwnd):
    process_id = get_wow_process_id(hwnd)
    print(process_id)
    h_process = win32api.OpenProcess(win32con.PROCESS_TERMINATE, win32con.FALSE, process_id)
    if h_process > 0:
        win32process.TerminateProcess(h_process, 0)

    win32api.TerminateProcess(h_process, 0)


def detect_wow_hang(hwnd):
    return ctypes.windll.user32.IsHungAppWindow(hwnd)


def close_if_hung(counter):
    hwnd_wow = get_wow_hwnd()
    print("detecting...")
    if hwnd_wow > 0 and detect_wow_hang(hwnd_wow):
        print("hung... counter: %d" % counter)
        if counter > 5:
            print("closing")
            close_wow(hwnd_wow)
            return 0
        else:
            return counter + 1

    return 0


def run():
    counter = 0
    while True:
        try:
            counter = close_if_hung(counter)
        except:
            pass

        time.sleep(2.5)


if __name__ == '__main__':
    run()
