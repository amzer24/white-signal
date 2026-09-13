"""Read-only PCM measurements; does not establish musical acceptance."""
from pathlib import Path
import hashlib, json, wave, math
import numpy as np
ROOT = Path(__file__).resolve().parent
def analyse(path):
    with wave.open(str(path), "rb") as stream:
        rate, channels, width = stream.getframerate(), stream.getnchannels(), stream.getsampwidth()
        assert width == 2, "Expected original 16-bit PCM"
        pcm = np.frombuffer(stream.readframes(stream.getnframes()), dtype="<i2").reshape(-1, channels)
    audio = pcm.astype(np.float64) / 32768
    mono = audio.mean(axis=1)[::4]
    hop, window = 120, 1024
    frames = np.lib.stride_tricks.sliding_window_view(mono, window)[::hop]
    spectral = np.log1p(np.abs(np.fft.rfft(frames * np.hanning(window), axis=1)))
    flux = np.maximum(np.diff(spectral, axis=0), 0).sum(axis=1)
    flux -= flux.mean()
    dt = hop / (rate / 4)
    correlations = {}
    for lag in range(math.ceil(60/180/dt), int(60/60/dt)+1):
        a,b = flux[:-lag],flux[lag:]
        correlations[lag] = float(np.dot(a,b) / max(np.linalg.norm(a)*np.linalg.norm(b),1e-12))
    peaks = [(lag,value) for lag,value in correlations.items() if value > correlations.get(lag-1,-1) and value >= correlations.get(lag+1,-1)]
    peaks.sort(key=lambda pair: pair[1], reverse=True)
    return {"file":path.name,"sha256":hashlib.sha256(path.read_bytes()).hexdigest(),"bytes":path.stat().st_size,"seconds":len(pcm)/rate,"sample_rate":rate,"channels":channels,"bits_per_sample":width*8,"sample_peak":float(np.abs(audio).max()),"full_scale_samples":int(np.count_nonzero((pcm==32767)|(pcm==-32768))),"rms":float(np.sqrt(np.mean(audio**2))),"end_one_second_rms":float(np.sqrt(np.mean(audio[-rate:]**2))),"periodicity_candidates":[{"bpm":60/(lag*dt),"correlation":value} for lag,value in peaks[:5]]}
if __name__ == "__main__":
    report = {"files":[analyse(ROOT/f"below-carrier-{letter}-original.wav") for letter in "ab"],"limits":"Periodicity peaks are not verified tempo, meter or phrase boundaries. PCM peak and full-scale counts do not establish true-peak safety, absence of distortion or vocal content. No loop edit, listening approval or runtime replacement has been made."}
    (ROOT/"below-carrier-analysis.json").write_text(json.dumps(report,indent=2))
    print(json.dumps(report,indent=2))
