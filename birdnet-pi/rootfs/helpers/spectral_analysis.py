import numpy as np
import scipy.io.wavfile as wavfile
import matplotlib.pyplot as plt
import os
import glob
import sys  # Import the sys module

from utils.helpers import get_settings

# Dependencies /usr/bin/pip install numpy scipy matplotlib

# Define the directory containing the WAV files
conf = get_settings()
input_directory = os.path.join(conf['RECS_DIR'], 'StreamData')
output_directory = os.path.join(conf['RECS_DIR'], 'Extracted/Charts')

# Ensure the output directory exists
if not os.path.exists(output_directory):
    os.makedirs(output_directory)

# Check if a command-line argument is provided
if len(sys.argv) > 1:
    # If an argument is provided, use it as the file to analyze
    wav_files = [sys.argv[1]]
else:
    # If no argument is provided, analyze all WAV files in the directory
    wav_files = glob.glob(os.path.join(input_directory, '*.wav'))

# Process each file
for file_path in wav_files:
    # Load the WAV file
    sample_rate, audio_data = wavfile.read(file_path)

    # If stereo, select only one channel
    if len(audio_data.shape) > 1:
        audio_data = audio_data[:, 0]

    # Apply the Hamming window to the audio data
    hamming_window = np.hamming(len(audio_data))
    windowed_data = audio_data * hamming_window

    # Compute the FFT of the windowed audio data
    audio_fft = np.fft.fft(windowed_data)
    audio_fft = np.abs(audio_fft)

    # Compute the frequencies associated with the FFT values
    frequencies = np.fft.fftfreq(len(windowed_data), d=1/sample_rate)

    # Select the range of interest
    idx = np.where((frequencies >= 150) & (frequencies <= 15000))

    # Calculate the saturation threshold based on the bit depth
    bit_depth = audio_data.dtype.itemsize * 8
    max_amplitude = 2**(bit_depth - 1) - 1
    saturation_threshold = 0.8 * max_amplitude

    # Plot the spectrum with a logarithmic Y-axis
    plt.figure(figsize=(10, 6))
    plt.semilogy(frequencies[idx], audio_fft[idx], label='Spectrum')
    plt.axhline(y=saturation_threshold, color='r', linestyle='--', label='Saturation Threshold')
    plt.xlabel("Frequency (Hz)")
    plt.ylabel("Amplitude (Logarithmic)")
    plt.title(f"Frequency Spectrum (150 - 15000 Hz) - {os.path.basename(file_path)}")
    plt.legend()
    plt.grid(True)

    # Save the plot as a PNG file
    output_filename = os.path.basename(file_path).replace('.wav', '_spectrum.png')
    plt.savefig(os.path.join(output_directory, output_filename))
    plt.close()  # Close the figure to free memory
