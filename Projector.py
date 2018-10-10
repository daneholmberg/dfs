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
        self.reduce_players(7, 8, 12, 5, 5)
        # self.reduce_players(4, 5, 7, 3, 3)
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
        self.players = list(players.values())

    def append_lineup(self, lineup):
        self.lineups.append(lineup)

    def lineups_iter(self, r):
        pool = tuple(self.players)
        n = len(pool)
        if r > n:
            return
        indices = list(range(r))
        
        lineup = Lineup([], 50000)
        for i in indices:
            added = lineup.add_player(self.players[i])
            if not added:
                incur = False
                indices[i] += 1
                for j in range(i+1, r):
                    indices[j] = indices[j-1] + 1
                break
        else:
            incur = True
            yield lineup
        while True:
            for i in reversed(range(r)):
                if indices[i] < i + n - r:
                    break
            else:
                return
            if i < lineup.len_players:
                lineup = Lineup(lineup.players[0:i])
            if incur:
                indices[i] += 1
                for j in range(i+1, r):
                    indices[j] = indices[j-1] + 1
            for k in range(lineup.len_players, r):
                added = lineup.add_player(pool[indices[k]])
                if not added:
                    incur = False
                    indices[k] += 1
                    for j in range(k+1, r):
                        indices[j] = indices[j-1] + 1
                    if indices[k] == k + n - r:
                        added = lineup.add_player(pool[indices[k]])
                        incur = True
                        if added:
                            continue
                    elif indices[k] > k + n - r:
                        incur = True
                    break
            else:
                for j in range(i+1, r):
                    indices[j] = indices[j-1] + 1
                incur = True
                yield lineup


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
        # print("here", len(self.li))
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