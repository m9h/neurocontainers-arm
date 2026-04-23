# T1Prep patches applied in t1prep-arm

Three local modifications on top of T1Prep `v0.3.3` upstream. Each is
small and should be contributed back; the plan is a single PR to
[ChristianGaser/T1Prep](https://github.com/ChristianGaser/T1Prep) once
we have the patches in a form upstream wants.

## 1. Deterministic-algorithm fallback for Blackwell

`src/t1prep/segment.py:966` hardcodes:

```python
torch.use_deterministic_algorithms(True)
```

On NVIDIA Blackwell (`sm_120`, DGX Spark), `grid_sampler_3d_backward_cuda`
has no deterministic kernel, causing segmentation to fail mid-run with:

```
RuntimeError: grid_sampler_3d_backward_cuda does not have a deterministic
implementation, but you set 'torch.use_deterministic_algorithms(True)'.
```

Our patch:

```python
torch.use_deterministic_algorithms(True, warn_only=True)
```

Behaviour change: non-deterministic ops now warn and continue (output
differences in the 1e-7 range, acceptable for inference).

## 2. Writable weight-cache for non-root runs

`deepmriprep` lazily creates its model-cache directory at
`/opt/T1Prep/env/lib/python3.12/site-packages/deepmriprep/data/models`
on first use. Under `docker run --user $(id -u):$(id -g)` the /opt
tree is root-owned and the lazy mkdir fails with `PermissionError`.

Our fix in the Dockerfile:

```dockerfile
RUN /opt/T1Prep/scripts/T1Prep --install \
 && chown -R 1000:1000 /opt/T1Prep
```

Pre-populating the weight cache at build time plus giving UID 1000
write access lets non-root runs work without an additional bind-mount.

## 3. Case-insensitive atlas filenames

`src/t1prep/segment.py:1200` and `1228` call:

```python
get_regions_mask(atlas, "Neuromorphometrics", …)
```

which expects a file named exactly `Neuromorphometrics.csv` in
`src/t1prep/data/templates_MNI152NLin2009cAsym/`. The shipped file is
`neuromorphometrics.csv` (lowercase). macOS default filesystems are
case-insensitive so upstream never noticed; Linux is case-sensitive
and segmentation aborts with `FileNotFoundError`.

Our fix in the Dockerfile:

```dockerfile
RUN cd /opt/T1Prep/src/t1prep/data/templates_MNI152NLin2009cAsym \
 && for f in neuromorphometrics.csv neuromorphometrics.nii.gz neuromorphometrics.txt; do \
      [ -e "$f" ] && ln -sf "$f" "N${f#n}"; \
    done
```

Adds uppercase symlinks. The proper upstream fix is either to rename
the shipped files to title-case or to update `get_regions_mask` to do a
case-insensitive filename match.
