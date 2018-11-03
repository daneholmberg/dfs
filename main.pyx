import csv
import argparse
import time

import dfs.projector

import old.Projector_old 

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("dfs_data")
    parser.add_argument("projected_data")
    parser.add_argument("type", nargs='?', default="median")
    parser.add_argument("-cpt", action="store_true")
    parser.add_argument("-cp", "--captain", default=None)
    parser.add_argument("-r", "--remove_players", default=[])
    parser.add_argument("-s", "--starting", default=[])
    parser.add_argument("-sc", "--starting_cpt", default=None)
    parser.add_argument("-ste", "--site", default="DK")
    parser.add_argument("-w", action="store_true")
    parser.add_argument("-l", "--lineup_type", default="normal")
    parser.add_argument("-ps", "--proj_source", default="ffa")
    parser.add_argument("-stack", action="store_true", help="Only return stacks")
    parser.add_argument("--restrict", default=None, help="Int representing how many times a player can be in lineups")
    parser.add_argument("--skip", default=1, help="skip over lineups")
    parser.add_argument("--limit", default=1000, help="How many lineups to sort through")
    parser.add_argument("--start_lin", default=0, help="Index to start looking for lineups")

    return parser.parse_args()

# if __name__ == "__main__":
def main(args=None):
    
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

    Projector = dfs.projector.Projector(dfs_data, projected_data, args.type, args.proj_source)
    Projector.build_projection_dict(starting_players, remove_players, args.site, args.lineup_type, args.captain)
    # Projector.build_dsf_dict()

    if args.cpt:
        iter_times = 6
    elif args.lineup_type == "college":
        iter_times = 8
    else:
        iter_times = 9

    Projector.add_values(args.site)
    Projector.purge_players(args.w, args.site, args.lineup_type)
    count = 0
    before = time.time()
    length = 26950000

    if args.cpt and not args.captain:
        remaining = len(Projector.players)
    else:
        remaining = 1

    #for cp in range(remaining):
    #if args.cpt and not args.captain:

    #    Projector.starting_players = Projector.starting_players[0:len(args.starting)]
    #    Projector.starting_players.append(Projector.players[cp])
    iterator = Projector.lineups_iter(iter_times, args.cpt, args.site, args.lineup_type)
    for lineup in iterator:
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

    Projector.sort_linesup(int(args.limit), int(args.skip), int(args.start_lin))
    Projector.make_stack(args.stack)
    if args.restrict:
        Projector.restrict_lineups(args.restrict)

    Projector.write_linesups_csv(args.type, args.site, args.lineup_type)
    print(time.time() - before)

    #dfs_data = csv.DictReader(open(args.dfs_data))
    #projected_data = csv.DictReader(open(args.projected_data))
    
    #Projector_old = old.Projector_old.Projector(dfs_data, projected_data, args.type)
    #Projector_old.build_projection_dict()
    #Projector_old.build_dsf_dict()



    #Projector_old.add_values()
    #Projector_old.purge_players()
    #count = 0
    #before = time.time()
    #length = 26950000

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
