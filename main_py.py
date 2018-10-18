import csv
import argparse
import time

import dfs.projector

import old.Projector_old 

from dfs.helper import test as abcd

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("dfs_data")
    parser.add_argument("projected_data")
    parser.add_argument("type", nargs='?', default="median")
    parser.add_argument("-cpt", action="store_true")
    parser.add_argument("-r", "--remove_players", default=[])
    parser.add_argument("-s", "--starting", default=[])
    parser.add_argument("-sc", "-starting_cpt", default=None)

    return parser.parse_args()

# if __name__ == "__main__":
def main(args=None):
    
    #dfs.projector = profile(dfs.projector)
    #abcd()
    if not args:
        args = parse_args()

    remove_players = args.remove_players
    starting_players = args.starting
    if remove_players:
        remove_players = list(map(lambda plyer: plyer.strip(), args.remove_players.split(",")))
    if starting_players:
        starting_players = list(map(lambda plyer: plyer.strip(), args.starting.split(",")))

    dfs_data = csv.DictReader(open(args.dfs_data))
    projected_data = csv.DictReader(open(args.projected_data))
    
    Projector = dfs.projector.Projector(dfs_data, projected_data, args.type)
    
    Projector.build_projection_dict(remove_players)
    # Projector.build_dsf_dict()

    if args.cpt:
        iter_times = 6
    else:
        iter_times = 9

    Projector.add_values()
    Projector.purge_players()
    count = 0
    before = time.time()
    length = 26950000
    
    Projector.lineups_iter = profile(Projector.lineups_iter)
    for lineup in Projector.lineups_iter(iter_times, args.cpt):
        lineup.add_points()
        in_it = False
        #for player in lineup.players:
        #    if player.name == "Keelan Cole":
        #        in_it = True
        #if not in_it:
        #    continue
        Projector.append_lineup(lineup)
        if count % 100000 == 0:
            print(time.time() - before, (count / length) * 100 )
        count += 1

    limit = 500
    Projector.sort_linesup(limit)
    
    

    Projector.write_linesups_csv(args.type)
    print(time.time() - before)

    dfs_data = csv.DictReader(open(args.dfs_data))
    projected_data = csv.DictReader(open(args.projected_data))
    
    Projector_old = old.Projector_old.Projector(dfs_data, projected_data, args.type)
    Projector_old.build_projection_dict()
    #Projector_old.build_dsf_dict()



    Projector_old.add_values()
    Projector_old.purge_players()
    count = 0
    before = time.time()
    length = 26950000

    #for lineup in Projector_old.lineups_iter(6, args.cpt):
    #    lineup.add_points()
    #    Projector_old.append_lineup(lineup)
    #    if count % 100000 == 0:
    #        print(time.time() - before, (count / length) * 100 )
    #    count += 1
    #Projector_old.sort_linesup()
    #Projector_old.write_linesups_csv()
    #print(time.time() - before)
    
if __name__ == "__main__":
    main()
