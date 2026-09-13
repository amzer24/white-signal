# Clear campaign resume

The title distinguishes Start/Resume Exploration from Resume Classic and New Classic Run. The selected exploration row reports the saved room title, a recoverable backup, or an unreadable save. It loads validated profile metadata once when the title is created or re-entered, not every frame. Preview is read-only and scene loading retains the existing save recovery behavior.

Validation: menu_resume_test.gd exercised fresh, saved, classic, backup and malformed states using a disposable profile. Byte comparison verified preview does not change a save; malformed contents remained untouched. NVIDIA-rendered 480x270 menu inspected with all six rows. Actual physical controller and full release QA remain outstanding.
