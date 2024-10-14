import os
import soundfile as sf
import numpy as np
from scipy.signal import butter, sosfiltfilt, resample_poly
import warnings
import sys
import concurrent.futures

# Bandpass filter with check for Nyquist frequency
def bandpass_filter(signal_data, sample_rate, lowcut, highcut, order=5):
    nyquist = sample_rate / 2
    if highcut >= nyquist:
        print(f"Warning: High cutoff frequency {highcut} Hz exceeds Nyquist frequency ({nyquist} Hz). Skipping this band.")
        return signal_data  # Skip filtering this band
    sos = butter(order, [lowcut / nyquist, highcut / nyquist], btype='band', output='sos')
    return sosfiltfilt(sos, signal_data)

def compress_frequency_band_stft(signal_data, sample_rate, original_band, target_band):
    # Perform Short-Time Fourier Transform (STFT)
    f, t, Zxx = stft(signal_data, fs=sample_rate, nperseg=2048)
    
    # Create a mask for frequencies within the original band
    band_mask = (f >= original_band[0]) & (f < original_band[1])
    
    # Get the portion of the frequency spectrum in the original band
    original_band_spectrum = Zxx[band_mask, :]

    # Calculate the compression ratio for frequencies
    compression_ratio = (target_band[1] - target_band[0]) / (original_band[1] - original_band[0])
    
    # Map frequencies to the target band by compressing or expanding the spectrum
    compressed_frequencies = target_band[0] + compression_ratio * (f[band_mask] - original_band[0])

    # Create an empty frequency spectrum for the output
    compressed_spectrum = np.zeros_like(Zxx)
    
    # Interpolate the original band spectrum to the new compressed frequencies
    for i, freq in enumerate(compressed_frequencies):
        closest_bin = np.argmin(np.abs(f - freq))
        compressed_spectrum[closest_bin, :] += original_band_spectrum[i, :]

    # Perform inverse STFT to convert back to the time domain
    _, compressed_signal = istft(compressed_spectrum, fs=sample_rate, nperseg=2048)
    
    # Ensure the output length matches the input length
    if len(compressed_signal) > len(signal_data):
        compressed_signal = compressed_signal[:len(signal_data)]
    elif len(compressed_signal) < len(signal_data):
        compressed_signal = np.pad(compressed_signal, (0, len(signal_data) - len(compressed_signal)), mode='constant')

    return compressed_signal

def process_wav_file(file_path, bands):
    try:
        # Load the audio file
        data, sample_rate = sf.read(file_path)
        
        # Explicitly recalculate the Nyquist frequency based on the file's actual sample rate
        nyquist_freq = sample_rate / 2
        print(f"Processing file: {file_path}")
        print(f"Sample rate: {sample_rate} Hz, Nyquist frequency: {nyquist_freq} Hz")
        
        if len(data.shape) > 1:
            data = data.mean(axis=1)

        with warnings.catch_warnings():
            warnings.simplefilter("ignore")

            combined_signal = np.zeros_like(data, dtype=np.float64)

            for band in bands:
                original_band = band['original_band']
                target_band = band['target_band']

                # Ensure the band's upper frequency is below Nyquist frequency
                if original_band[1] > nyquist_freq:
                    print(f"Warning: Band {original_band[0]}-{original_band[1]} Hz exceeds Nyquist frequency ({nyquist_freq} Hz). Skipping.")
                    continue  # Skip this band
                else:
                    # Process valid frequency bands
                    band_data = bandpass_filter(data, sample_rate, original_band[0], original_band[1], order=8)
                    compressed_band = compress_frequency_band_stft(band_data, sample_rate, original_band, target_band)
                    combined_signal += compressed_band

            # Resample the combined signal and clip it to ensure it's within range
            combined_signal = np.clip(combined_signal, -1.0, 1.0)
            target_output_sample_rate = 48000
            resampled_signal = resample_poly(combined_signal, target_output_sample_rate, sample_rate)

            # Write the output back to the same file (overwrite)
            sf.write(file_path, resampled_signal, target_output_sample_rate, subtype='PCM_16')
            print(f"Processed and updated: {file_path}")

    except Exception as e:
        print(f"Error processing {file_path}: {e}")

def process_wav_file_with_timeout(file_path, bands, timeout=20):
    try:
        with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
            future = executor.submit(process_wav_file, file_path, bands)
            future.result(timeout=timeout)
    except concurrent.futures.TimeoutError:
        print(f"Skipping {file_path} due to timeout.")
    except Exception as e:
        print(f"Error processing {file_path}: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python bat_wav_translate.py <input_wav_file>")
        sys.exit(1)

    input_file = sys.argv[1]

    # Define the frequency bands
    bands = [
        {'original_band': (18000, 35000), 'target_band': (0, 5000)},
        {'original_band': (35000, 48000), 'target_band': (5000, 10000)},
        {'original_band': (48000, 60000), 'target_band': (10000, 14500)},
        {'original_band': (75000, 85000), 'target_band': (14500, 14750)},
        {'original_band': (105000, 115000), 'target_band': (14750, 15000)},
    ]

    process_wav_file_with_timeout(input_file, bands)
