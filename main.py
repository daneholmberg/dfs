import csv
import argparse
import time

from Projector import Projector

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("dfs_data")
    parser.add_argument("projected_data")
    parser.add_argument("type", nargs='?', default="median")

    return parser.parse_args()

if __name__ == "__main__":
    
    args = parse_args()
    
    dfs_data = csv.DictReader(open(args.dfs_data))
    projected_data = csv.DictReader(open(args.projected_data))

    Projector = Projector(dfs_data, projected_data, args.type)
    Projector.build_projection_dict()
    # Projector.build_dsf_dict()



    Projector.add_values()
    Projector.purge_players()
    count = 0
    before = time.time()
    for lineup in Projector.lineups_iter(9):
        lineup.add_points()
        Projector.append_lineup(lineup)
    Projector.sort_linesup()
    Projector.write_linesups_csv()
    # Projector.build_all_lineups(50000, True)
    print(time.time() - before)


    
