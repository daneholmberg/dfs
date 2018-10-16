import csv

def write_csv(name, columns, rows):
    with open(name, 'w') as csv_file:
        writer = csv.DictWriter(csv_file, columns)

        writer.writeheader()
        writer.writerows(rows)

