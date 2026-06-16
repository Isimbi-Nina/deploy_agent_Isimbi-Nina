#!/bin/bash
set -e

echo "Student Attendance Tracker"

read -p "What would you like to call this attendance tracker: " name

parent_dir="attendance_tracker_${name}"
archive="attendance_tracker_${name}_archive"

#Trap SIGINT signal
handle_user_interrupt() {
    echo "Saving and exiting..."
    zip -r "${archive}.zip" "$parent_dir"
    rm -rf "$parent_dir"
    exit 1

}

trap handle_user_interrupt SIGINT




#Create project directories and files 

if [[ -d "$parent_dir" ]]; then
echo  "Directory '$parent_dir' already exists."
read -p "Delete and create it again? (yes/no): " choice
if [[ "$choice" == "yes" ]]; then
rm -rf "$parent_dir"
else 
echo "Exiting..."
exit 0
fi
fi

mkdir -p "$parent_dir/Helpers" && mkdir -p "$parent_dir/reports"

cat > "$parent_dir/Helpers/config.json" << END
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
END


cat > "$parent_dir/Helpers/assets.csv" << END
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
END



cat > "$parent_dir/reports/reports.log" << END
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
END



cat > "$parent_dir/attendance_checker.py" << END 
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    # 1. Load Config
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)
    
    # 2. Archive old reports.log if it exists
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    # 3. Process Data
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']
        
        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")
        
        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])
            
            # Simple Math: (Attended / Total) * 100
            attendance_pct = (attended / total_sessions) * 100
            
            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."
            
            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
END

echo "Project directories and files created."

#Dynamic Configuration
read -p "Do you want to update the attendance thresholds? (yes/no): " answer

if [[ "$answer" == "yes" ]]; then

while true; do
read -p "Enter new Warning threshold (default 75%): " warning
read -p "Enter new Failure threshold (default 50%): " failure

if [[ ! "$warning" =~ ^[0-9]+$ ]] || [[ ! "$failure" =~ ^[0-9]+$ ]]; then
echo "Invalid input. Please enter numbers only."
elif [[ $warning -lt $failure ]]; then
echo "Warning threshold cannot be lower than failure threshold."
else
sed -i "s|\"warning\": .*|\"warning\": $warning|" "$parent_dir/Helpers/config.json"
sed -i "s|\"failure\": .*|\"failure\": $failure|" "$parent_dir/Helpers/config.json"
echo "Thresholds updated."
break
fi

done

fi

#Environment validation
echo "Running health check..."

if python3 --version; then
    echo "python3 is installed."
else
    echo "Warning: python3 is not installed."
fi

for file in "$parent_dir/attendance_checker.py" \
    "$parent_dir/Helpers/config.json" \
    "$parent_dir/Helpers/assets.csv" \
    "$parent_dir/reports/reports.log"; do
    if [[ ! -f "$file" ]]; then
    echo "$file is missing"
    fi
done

