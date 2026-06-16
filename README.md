# School Attendance Tracker 

## How to Run

1. Clone this repository
2. Make the script executable:
```bash
   chmod +x setup_project.sh
```
3. Run the script:
```bash
   ./setup_project.sh
```
4. Follow the prompts given

## How to Trigger the Archive Feature

While the script is running, press **Ctrl+C**;

The script will:
1. Detect the interrupt signal (SIGINT)
2. Bundle the current (incomplete) project directory into an archive named `attendance_tracker_{input}_archive.zip`
3. Delete the incomplete directory to keep your workspace clean

## Video Walkthrough link
https://www.loom.com/share/7d0f8f3350bd4f45870153cff54f253b
