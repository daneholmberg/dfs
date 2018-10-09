import time
import sys

from copy import copy, deepcopy

from collections import OrderedDict

from players.Player import Player
from Lineup import Lineup

from utilities.helper import write_csv
from utilities.constants import PLAYER_COLUMNS, LINEUP_COLUMNS

class Projector:
    def __init__(self, draftkings_data, projected_data, tpe="median"):
        self.tpe = tpe
        self.lineups = []
        self.players = {}
        self.players_dict = {"QBs": [], "RBs": [], "WRs": [], "TEs": [], "Flexes": [], "DSTs": []}
        self.draftkings_data = draftkings_data
        self.projected_data = projected_data

    def build_players_dict(self):
        for player in self.players.values():
            if player.position == "QB":
                self.players_dict['QBs'].append(player)
            elif player.position == "RB":
                self.players_dict['RBs'].append(player)
                self.players_dict['Flexes'].append(player)
            elif player.position == "WR":
                self.players_dict['WRs'].append(player)
                self.players_dict['Flexes'].append(player)
            elif player.position == "TE":
                self.players_dict['TEs'].append(player)
                self.players_dict['Flexes'].append(player)
            elif player.position == "DST":
                self.players_dict['DSTs'].append(player)

    def build_projection_dict(self):
        for proj_row in self.projected_data:
            unique_key = proj_row['player'] + proj_row['team'] + proj_row['position']
            if unique_key not in self.players:
                self.players[unique_key] = Player(proj_row['player'])

            self.players[unique_key].update_player_proj(proj_row)
        for dfs_row in self.draftkings_data:
            if "Roster Position" in dfs_row and dfs_row['Roster Position'] == "CPT":
                continue
            dfs_row['Name'] = self.clean_name(dfs_row['Name'])
            dfs_row['TeamAbbrev'] = self.clean_abbr(dfs_row['TeamAbbrev'])
            unique_key_dfs = dfs_row['Name'] + dfs_row['TeamAbbrev'] + dfs_row['Position']
            if unique_key_dfs not in self.players:
                self.players[unique_key_dfs] = Player(dfs_row['Name'])
            self.players[unique_key_dfs].update_player_dfs(dfs_row)

    def clean_name(self, name):
        name = name.replace(" III", "")
        name = name.replace(" II", "")
        name = name.replace(" Jr.", "")
        name = name.strip()
        name = name.replace("TJ ", "T.J. ")
        name = name.replace("O'Shaughnessy", "OShaughnessy")
        name = name.replace("De'Anthony Thomas", "DeAnthony Thomas")
        
        if name == "Le'Veon Bell":
            name = "LeVeon Bell"
        return name

    def clean_abbr(self, abbr):
        abbr = abbr.replace("JAX", "JAC")
        return abbr

    def purge_players(self):
        toRemove = []
        
        for key, player in self.players.items():
            if not hasattr(player, "salary"):
                toRemove.append(key)
            if not hasattr(player, "median"):
                toRemove.append(key)
        for key in toRemove:
            self.players.pop(key)
        
        self.order_players_by_value()
        # self.sorted_players = sorted(self.players.values(), key=lambda player: player.median_value)
        # self.build_players_dict()

    def order_players_by_value(self):
        if self.tpe == "ceil":
            self.players = sorted(self.players.values(), key=lambda player: player.upper_value, reverse=True)
        elif self.tpe == "median":
            self.players = sorted(self.players.values(), key=lambda player: player.median_value, reverse=True)
        else:
            self.players = sorted(self.players.values(), key=lambda player: player.lower_value, reverse=True)
        # self.reduce_players(7, 8, 12, 5, 5)
        self.reduce_players(4, 5, 7, 3, 3)
        print(len(self.players))
        self.write_player_csv()

        # self.players = sorted(self.players, key=lambda player: player.upper, reverse=True)
        # for player in self.players:
        #     # if player.position in ["TE", "RB", "WR"]:
        #     if player.position in ["TE"]:
        #         print(player.name, player.upper_value, player.position, player.team, player.upper, player.salary)

    def reduce_players(self, qb_num, rb_num, wr_num, te_num, dst_num):
        players = {i: player for i, player in enumerate(self.players)}
        qb_count = 0
        rb_count = 0
        wr_count = 0
        te_count = 0
        dst_count = 0
        toDel = []
        for i, player in players.items():
            if player.position == "QB":
                qb_count = qb_count + 1
                if qb_count > qb_num:
                    toDel.append(i)
            if player.position == "RB":
                rb_count = rb_count + 1
                if rb_count > rb_num:
                    toDel.append(i)
            if player.position == "WR":
                wr_count = wr_count + 1
                if wr_count > wr_num:
                    toDel.append(i)
            if player.position == "TE":
                te_count = te_count + 1
                if te_count > te_num:
                    toDel.append(i)
            if player.position == "DST":
                dst_count = dst_count + 1
                if dst_count > dst_num:
                    toDel.append(i)
        for ind in toDel:
            players.pop(ind)
        self.players = players.values()


    def build_all_lineups(self, cap=50000, remove_needed=True):
        before = time.time()
        for i, player_i in enumerate(self.players):
            if i % 1 == 0:
                print(f"Time passed: {time.time() - before} {i}")
            # if i != 0 and i % 75 == 0:
            #     break
            #     print(i)
            # player_cpt = deepcopy(player_i) 

            # player_cpt.salary = float(player_cpt.salary) * 1.5
            # player_cpt.upper = float(player_cpt.upper) * 1.5
            # player_cpt.median = float(player_cpt.median) * 1.5
            # player_cpt.lower = float(player_cpt.lower) * 1.5
            # print(player_i.name, player_i.salary)

            self.lineups.append(Lineup([], cap))
            cont = self.lineups[-1].add_player(player_i, remove_needed)
            
            if not cont:
                continue

            for j, player_j in enumerate(self.players):

                if j <= i:
                    create_new = True
                    continue
                if j-i > 1 and (create_new or len(self.lineups[-1].players) == 3):
                    self.lineups.append(Lineup(self.lineups[-1].players[0:1], cap))
                cont = self.lineups[-1].add_player(player_j, remove_needed)
                if not cont:
                    create_new = False
                    continue
                else:
                    create_new = True
                for k, player_k in enumerate(self.players):
                    if k == 0:
                        print(f"Time passed: {time.time() - before} i: {i}, j: {j}")
                    if k <= j or k <= i:
                        create_new = True
                        continue
                    if k-j > 1 and (create_new or len(self.lineups[-1].players) == 4):
                        self.lineups.append(Lineup(self.lineups[-1].players[0:2], cap))
                    cont = self.lineups[-1].add_player(player_k, remove_needed)
                    if not cont:
                        create_new = False
                        continue
                    else:
                        create_new = True

                    for l, player_l in enumerate(self.players):
                        if l <= k or l <= j or l <= i :
                            create_new = True
                            continue
                        if l-k > 1 and (create_new or len(self.lineups[-1].players) == 5):
                            self.lineups.append(Lineup(self.lineups[-1].players[0:3], cap))
                        cont = self.lineups[-1].add_player(player_l, remove_needed)
                        if not cont:
                            create_new = False
                            continue
                        else:
                            create_new = True

                        for m, player_m in enumerate(self.players):

                            if m <= l or m <= k or m <= j or m <= i:
                                create_new = True
                                continue
                            if m-l > 1 and (create_new or len(self.lineups[-1].players) == 6):
                                self.lineups.append(Lineup(self.lineups[-1].players[0:4], cap))
                            cont = self.lineups[-1].add_player(player_m, remove_needed)
                            if not cont:
                                create_new = False
                                continue
                            else:
                                create_new = True

                            for n, player_n in enumerate(self.players):

                                if n <= m or n <= l or n <= k or n <= j or n <= i:
                                    create_new = True
                                    continue
                                if n-m > 1 and (create_new or len(self.lineups[-1].players) == 7):
                                    self.lineups.append(Lineup(self.lineups[-1].players[0:5], cap))
                                cont = self.lineups[-1].add_player(player_n, remove_needed)
                                if not cont:
                                    create_new = False
                                    continue
                                else:
                                    create_new = True

                                for o, player_o in enumerate(self.players):

                                    if o <= n or o <= m or o <= l or o <= k or o <= j or o <= i:
                                        create_new = True
                                        continue
                                    if o-n > 1 and (create_new or len(self.lineups[-1].players) == 8):
                                        self.lineups.append(Lineup(self.lineups[-1].players[0:6], cap))
                                    cont = self.lineups[-1].add_player(player_o)
                                    if not cont:
                                        create_new = False
                                        continue
                                    else:
                                        create_new = True

                                    for p, player_p in enumerate(self.players):

                                        if p <= o or p <= n or p <= m or p <= l or p <= k or p <= j or p <= i:
                                            create_new = True
                                            continue
                                        if p-o > 1 and (create_new or len(self.lineups[-1].players) == 9):
                                            self.lineups.append(Lineup(self.lineups[-1].players[0:7], cap))
                                        cont = self.lineups[-1].add_player(player_p)
                                        if not cont:
                                            create_new = False
                                            continue
                                        else:
                                            create_new = True

                                        # self.lineups = self.lineups + [Lineup(self.lineups[-1].players[0:8], cap, player_q) for q, player_q in enumerate(self.players)
                                        #                      if q-p > 1 and self.lineups[-1].create_new(player_q)]

                                        for q, player_q in enumerate(self.players):
                                            if q <= p or q <= o or q <= n or q <= m or q <= l or q <= k or q <= j or q <= i:
                                                create_new = True
                                                continue
                                            if q-p > 1 and create_new:
                                                self.lineups.append(Lineup(self.lineups[-1].players[0:8], cap))
                                            cont = self.lineups[-1].add_player(player_q)

                                            if not cont:
                                                create_new = False
                                                continue
                                            else:
                                                create_new = True
        
        for lineup in self.lineups:
            lineup.add_points()
        print(len(self.lineups))
        self.lineups = list(filter(lambda lineup: len(lineup.players) == 9, self.lineups))
        print(len(self.lineups))
        # for lineup in self.lineups:
        #     lineup.order_by_pos()
        print(len(self.lineups))
        
        self.sort_linesup()

        self.write_linesups_csv()

        print(time.time() - before)

    def sort_linesup(self):
        if self.tpe == "floor":
            self.lineups = sorted(self.lineups, key=lambda lineup: lineup.points_floor, reverse=True)
        elif self.tpe == "ceil":
            self.lineups = sorted(self.lineups, key=lambda lineup: lineup.points_ceil, reverse=True)
        else:
            self.lineups = sorted(self.lineups, key=lambda lineup: lineup.points_avg, reverse=True)
        count = 0
        for lineup in self.lineups:
            if count > 10:
                break
            # print(lineup)
            count = count + 1
        #     for ply in lineup.players:
        #         try:
        #             print(ply.name, ply.upper_value, ply.upper, ply.salary, ply.team, ply.position)
        #             print("")
        #         except:
        #             print(ply.name, ply.upper, ply.salary, ply.team, ply.position)
        #             print("")

    def write_player_csv(self):
        players = [vars(player) for player in self.players]
        write_csv("player_values.csv", PLAYER_COLUMNS, players)

    def write_linesups_csv(self, limit=10):
        rows = []
        for i, lineup in enumerate(self.lineups):
            if i == limit:
                break
            row_lineup = {}
            for key, var in vars(lineup).items():
                if key in LINEUP_COLUMNS:
                    row_lineup[key] = var
            for player in lineup.players:
                rows.append({})
                rows[-1]['lineup_num'] = i+1
                for key, var in vars(player).items():
                    if key in LINEUP_COLUMNS:
                        rows[-1][key] = var
                rows[-1] = {**rows[-1], **row_lineup}
                # print(rows[-1])

        write_csv("linesups.csv", LINEUP_COLUMNS, rows)


    # def build_lineups_recur(self, player, lineup=Lineup()):
    #     if lineup.salary_remaining < 0 or len(lineup.players) == 6:
    #         return lineup
    #     else 
                
    

    def add_values(self):
        for player in self.players.values():
            player.get_value()