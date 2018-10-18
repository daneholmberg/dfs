import csv

def write_csv(name, columns, rows):
    with open(name, 'w') as csv_file:
        writer = csv.DictWriter(csv_file, columns)

        writer.writeheader()
        writer.writerows(rows)

def test():
    for i in range(100000):
        a = i
        b = 1

        c = 1000
        l = [z for z in range(1000)]