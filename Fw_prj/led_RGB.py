import RPi.GPIO as GPIO
import time
from config import LED_RED, LED_BLUE, LED_GREEN
# Setup GPIO pins
def setup_pins():
    pins = [LED_RED, LED_BLUE, LED_GREEN]
    GPIO.setmode(GPIO.BCM)
    for pin in pins:
        GPIO.setup(pin, GPIO.OUT)

# Function to control the blue light (GPIO 27)
def blue_light():
    GPIO.output(LED_BLUE, GPIO.HIGH)
    GPIO.output(LED_RED, GPIO.LOW)
    GPIO.output(LED_GREEN, GPIO.LOW)


# Function to control the red light (GPIO 22)
def red_light():
    GPIO.output(LED_RED, GPIO.HIGH)
    GPIO.output(LED_BLUE, GPIO.LOW)
    GPIO.output(LED_GREEN, GPIO.LOW)


# Function to control the green light (GPIO 23)
def green_light():
    GPIO.output(LED_GREEN, GPIO.HIGH)
    GPIO.output(LED_RED, GPIO.LOW)
    GPIO.output(LED_BLUE, GPIO.LOW)

def turn_off():
    GPIO.output(LED_GREEN, GPIO.LOW)
    GPIO.output(LED_RED, GPIO.LOW)
    GPIO.output(LED_BLUE, GPIO.LOW)

