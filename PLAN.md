# Add "Apply script on bulk and merge" mode

**Feature:**

- From the Scripts screen, add a new option on each script called "Apply script on bulk and merge".
- Tapping it opens the file picker with multi-select enabled for .txt files.
- The app runs the selected script on the contents of every picked file independently.
- Results are combined into a single merged text file in this format:
  ```
  filename1.txt
  -----------------------------------
  <processed content of file 1>

  filename2.txt
  -----------------------------------
  <processed content of file 2>
  ```
- After processing, an export sheet appears to save the merged file as a .txt.
- A progress popup shows which file is currently being processed (e.g. "Processing 3 of 12: notes.txt").

**Where it lives:**

- New action on each script row in the Scripts list (accessible via a menu button next to the existing Run button), and also from inside the Script Editor next to the existing Run button.

**Behavior:**

- Files that fail to read are skipped and noted in the merged output with an `(error reading file)` marker under their filename separator.
- The editor's current text is not modified by this action — it only produces the merged export file.

