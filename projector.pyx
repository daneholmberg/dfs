# cython: profile=True

# distutils: define_macros=CYTHON_TRACE_NOGIL=1
# cython: linetrace=True
# cython: binding=True

import time
import sys
import numpy as np
from random import sample

import line_profiler

from copy import copy, deepcopy

from collections import OrderedDict

cimport Player
cimport Lineup

from line_profiler import LineProfiler
from utilities.helper import write_csv
from utilities.constants import PLAYER_COLUMNS, LINEUP_COLUMNS

from cpython cimport array
import array

from libc.stdlib cimport malloc, free

class Projector:
    def __init__(self, dfs_data, projected_data, tpe="median", source="ffa"):
        cdef str proj_type
        cdef list lineups
        cdef dict players

        self.starting_players = []
        self.proj_type = tpe
        self.lineups = []
        self.players = {}
        self.desig_cpt = False
        #self.players_dict = {"QBs": [], "RBs": [], "WRs": [], "TEs": [], "Flexes": [], "DSTs": []}
        self.dfs_data = dfs_data
        self.projected_data = self.normalize_data(projected_data)
        
        
    # def build_players_dict(self):
    #     for player in self.players.values():
    #        if player.position == "QB":
    #            self.players_dict['QBs'].append(player)
    #        elif player.position == "RB":
    #            self.players_dict['RBs'].append(player)
    #            self.players_dict['Flexes'].append(player)
    #        elif player.position == "WR":
    #            self.players_dict['WRs'].append(player)
    #            self.players_dict['Flexes'].append(player)
    #        elif player.position == "TE":
    #            self.players_dict['TEs'].append(player)
    #            self.players_dict['Flexes'].append(player)
    #        elif player.position == "DST":
    #            self.players_dict['DSTs'].append(player) 
    def normalize_data(self, projected_data, source):
        if source == "ffa":
            return projected_data
        elif source == "pff":
            npd = []
            for row in projected_data:
                npd.append({})
                plyer = npd[-1]
                plyer['player'] = self.clean_name(row['Name'])
                if row['Team'] == "HST":
                    row['Team'] = "HOU"
                plyer['team'] = row['Team']
                plyer['position'] = row['Pos'].upper()
                plyer['points'] = row['Pts']
                plyer['lower'] = row['Pts']
                plyer['upper'] = row['Pts']
                plyer['sdPts'] = "0"
                plyer['dropoff'] = "0"
                plyer['sdRank'] = "0"
                plyer['risk'] = "0"
            return npd

    def build_projection_dict(self, starting_players, removed_players, site="DK", lineup_type="normal", captain=None):
        for proj_row in self.projected_data:
            if proj_row['player'] in removed_players:
                continue
            if lineup_type == "normal":
                team = proj_row['team']
            else:
                team = ""
            unique_key = proj_row['player'] + team + proj_row['position']
            if unique_key not in self.players:
                self.players[unique_key] = Player.Player(proj_row['player'])
            self.players[unique_key].update_player_proj(proj_row)

        if site == "DK":
            self.get_draft_kings_data(starting_players, removed_players, lineup_type, captain)
        elif site == "yahoo":
            self.get_yahoo_data(starting_players, removed_players, captain)

    
    def get_draft_kings_data(self, starting_players, removed_players, lineup_type, captain):
        for dfs_row in self.dfs_data:
            if "Roster Position" in dfs_row and dfs_row['Roster Position'] == "CPT":
                continue
            if dfs_row['Name'] in removed_players:
                continue
            dfs_row['Name'] = self.clean_name(dfs_row['Name'])
            dfs_row['TeamAbbrev'] = self.clean_abbr(dfs_row['TeamAbbrev'])
            if lineup_type == "normal":
                team = dfs_row['TeamAbbrev']
            else:
                team = ""
            unique_key_dfs = dfs_row['Name'] + team + dfs_row['Position']
            if unique_key_dfs not in self.players:
                self.players[unique_key_dfs] = Player.Player(dfs_row['Name'])
            self.players[unique_key_dfs].update_player_dfs(dfs_row)
            if self.players[unique_key_dfs].name == captain:
                self.desig_cpt = True
                #self.players[unique_key_dfs].make_cpt()
                self.starting_players.append(self.players[unique_key_dfs])
            elif self.players[unique_key_dfs].name in starting_players:
                self.starting_players.append(self.players[unique_key_dfs])


    def get_yahoo_data(self, starting_players, removed_players, captain):
        for dfs_row in self.dfs_data:
            if dfs_row['Position'] != "DEF":
                name = f"{dfs_row['First Name']} {dfs_row['Last Name']}"
            else:
                name = dfs_row['Last Name']
                dfs_row['Position'] = "DST"
            if name in removed_players:
                continue
            name = self.clean_name(name)
            dfs_row['Team'] = self.clean_abbr(dfs_row['Team'])
            unique_key_dfs = name + dfs_row['Team'] + dfs_row['Position']
            if unique_key_dfs not in self.players:
                self.players[unique_key_dfs] = Player.Player(name)
            self.players[unique_key_dfs].update_player_dfs(dfs_row, "yahoo")
            if self.players[unique_key_dfs].name == captain:
                self.desig_cpt = True
                #self.players[unique_key_dfs].make_cpt()
                self.starting_players.append(self.players[unique_key_dfs])
            elif self.players[unique_key_dfs].name in starting_players:
                self.starting_players.append(self.players[unique_key_dfs])


    def clean_name(self, name):
        name = name.replace(" III", "")
        name = name.replace(" II", "")
        name = name.replace(" Jr.", "")
        name = name.strip()
        name = name.replace("TJ ", "T.J. ")
        name = name.replace("O'Shaughnessy", "OShaughnessy")
        name = name.replace("De'Anthony Thomas", "DeAnthony Thomas")
        name = name.replace("Odell Beckham Jr.", "Odell Beckham")
        name = name.replace(" DST", "")
        
        
        if name == "Le'Veon Bell":
            name = "LeVeon Bell"
        return name

    def clean_abbr(self, abbr):
        abbr = abbr.replace("JAX", "JAC")
        return abbr

    def purge_players(self, write, site, lineup_type):
        toRemove = []
        for key, player in self.players.items():
            if not player.salary:
                toRemove.append(key)
            elif not player.median:
                toRemove.append(key)

        for key in toRemove:
            self.players.pop(key)
        self.order_players_by_value(write, site, lineup_type)

        # self.sorted_players = sorted(self.players.values(), key=lambda player: player.median_value)
        # self.build_players_dict()

    def order_players_by_value(self, write, site, lineup_type):
        if self.proj_type == "ceil":
            self.players = sorted(self.players.values(), key=lambda player: player.upper_value, reverse=True)
        elif self.proj_type == "median":
            self.players = sorted(self.players.values(), key=lambda player: player.median_value, reverse=True)
        else:
            self.players = sorted(self.players.values(), key=lambda player: player.lower_value, reverse=True)
        if write:
            self.write_player_csv(site, lineup_type)
        #self.reduce_players(7, 10, 14, 7, 5) 
        #self.reduce_players(6, 12, 15, 7, 5) # 2 players already
        #self.reduce_players(6, 15, 20, 10, 5) # 4 players already
        #self.reduce_players(7, 22, 25, 15, 5) # 4 players already
        self.reduce_players(5, 9, 12, 5, 5) # 75
        #self.reduce_players(5, 12, 14, 9, 5) 
        #self.reduce_players(5, 7, 9, 5, 5) # 6-7

        #self.reduce_players(9, 12, 15, 7, 5) # 51 college
        self.players.reverse()
        self.players = sample(self.players, len(self.players))
        for s_player in self.starting_players:
            self.players.insert(0, s_player)

        print(f"Len players: {len(self.players)-len(self.starting_players)}")

        # self.reduce_players(4, 17, 14, 9, 12)7 8 12 5 5

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

    #def init_numpy(self, r):
    #    cdef int[:] np_arr = np.ones(r, dtype=np.intc)
    #    cdef int i
    #    for i in range(r):
    #        np_arr[i] = i
    #    return np_arr

    def lineups_iter(self, int r, cpt=False, site="DK", lineup_type="normal"):
        if site == "DK":
            s_cap = 50000
        elif site == "yahoo":
            s_cap = 200
        

        cdef tuple pool
        cdef int n
        #cdef int* indices 
        cdef Lineup.Lineup linesup
        #cdef int[:] indices = self.init_numpy(r)
        cdef list indices
        indices = list(range(r))
        #cdef int* indices = <int *> malloc(r * sizeof(int))
        #indices = [1, 2, 3, 4, 5, 6, 7, 8, 9]

        pool = tuple(self.players)
        starters = deepcopy(self.starting_players)
        n = len(pool)
        if r > n:
            return

        if cpt and not self.desig_cpt:
            starters = [pool[0]]
        lineup = Lineup.Lineup(starters, s_cap, captain_mode=cpt, lineup_type=lineup_type)

        
        #if cpt and not self.desig_cpt:
        #    remaining = n
        #    starters.append(None)
        #else:
        #    remaining = 1

        cdef int len_starters = len(starters)
        cdef int i
        cdef int j
        cdef int k
        cdef int cpt_int = 0
        cdef bint incur

        for i in range(len_starters,r):
            added = lineup.add_player(self.players[i], cpt)
            if not added:
                incur = False

                indices[i] = indices[i] + 1

                for j in range(i+1, r):
                    indices[j] = indices[j-1] + 1
                break
        else:
            incur = True
            yield lineup
        while True:
            for i in reversed(range(len_starters,r)):
                if indices[i] < i + n - r:
                    break
            else:
                if cpt and not self.desig_cpt and cpt_int < n:
                    indices = self.reset_inds_cpt(cpt_int, r)
                    lineup = Lineup.Lineup([self.players[cpt_int]], s_cap, captain_mode=cpt, lineup_type=lineup_type)
                    cpt_int += 1
                    for v in range(len_starters,r):
                        added = lineup.add_player(self.players[v], cpt)
                        if not added:
                            incur = False

                            indices[v] = indices[v] + 1

                            for x in range(v+1, r):
                                indices[x] = indices[x-1] + 1
                            break
                    else:
                        incur = True
                        yield lineup
                    continue
                return

            if i < lineup.len_players:
                lineup = Lineup.Lineup(lineup.players[0:i], captain_mode=cpt, lineup_type=lineup_type, has_cpt=True)
            if incur:
                indices[i] += 1
                for j in range(i+1, r):
                    indices[j] = indices[j-1] + 1
            for k in range(lineup.len_players, r):
                added = lineup.add_player(pool[indices[k]], cpt)

                if not added:
                    incur = False
                    indices[k] += 1
                    for j in range(k+1, r):
                        indices[j] = indices[j-1] + 1
                    if indices[k] == k + n - r:
                        added = lineup.add_player(pool[indices[k]], cpt)
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

    def reset_inds_cpt(self, i, length):
        new_inds = [i]
        for j in range(length-1):
            #if len(new_inds) == length:
            #    break
            #if j == i:
            #    continue
            #else:
            new_inds.append(j)
        return new_inds

    def sort_linesup(self, limit=50, skip=1, start=0):
        if self.proj_type == "floor":
            self.lineups = sorted(self.lineups, key=lambda lineup: lineup.points_floor, reverse=True)[start:limit:skip]
        elif self.proj_type == "ceil":
            self.lineups = sorted(self.lineups, key=lambda lineup: lineup.points_ceil, reverse=True)[start:limit:skip]
        else:
            self.lineups = sorted(self.lineups, key=lambda lineup: lineup.points_avg, reverse=True)[start:limit:skip]

        count = 0


    def write_player_csv(self, site, lineup_type):
        if lineup_type == "normal":
            lineup_type = ""
        players = []
        for player in self.players:
            players.append({})
            players[-1]['name'] = player.name
            players[-1]['salary'] = player.salary
            players[-1]['position'] = player.position
            players[-1]['team'] = player.team
            players[-1]['opposing_team'] = player.opposing_team
            players[-1]['upper_value'] = player.upper_value
            players[-1]['median_value'] = player.median_value
            players[-1]['lower_value'] = player.lower_value
            players[-1]['upper'] = player.upper
            players[-1]['median'] = player.median
            players[-1]['lower'] = player.lower
            players[-1]['sdPts'] = player.sdPts
            players[-1]['dropoff'] = player.dropoff
            players[-1]['sdRank'] = player.sdRank
            players[-1]['risk'] = player.risk

        write_csv(f"player_values/player_values_{site}_{lineup_type}.csv", PLAYER_COLUMNS, players)



    def write_linesups_csv(self, tpe, site, lineup_type):
        rows = []
        for i, lineup in enumerate(self.lineups):
            row_lineup = {}
            row_lineup['points_avg'] = lineup.points_avg
            row_lineup['points_ceil'] = lineup.points_ceil
            row_lineup['points_floor'] = lineup.points_floor
            row_lineup['salary_remaining'] = lineup.salary_remaining
            row_lineup['stack'] = lineup.stack

            for player in lineup.players:
                rows.append({})
                rows[-1]['lineup_num'] = i+1
                rows[-1]['name'] = player.name
                rows[-1]['salary'] = player.salary
                rows[-1]['position'] = player.position
                rows[-1]['team'] = player.team
                rows[-1]['opposing_team'] = player.opposing_team
                rows[-1]['upper_value'] = player.upper_value
                rows[-1]['median_value'] = player.median_value
                rows[-1]['lower_value'] = player.lower_value
                rows[-1]['upper'] = player.upper
                rows[-1]['median'] = player.median
                rows[-1]['lower'] = player.lower

                rows[-1] = {**rows[-1], **row_lineup}
            rows.append({})
        if lineup_type == "normal":
            lineup_type = ""
        
        write_csv(f"lineups/linesups_{site}_{tpe}_{lineup_type}.csv", LINEUP_COLUMNS, rows)


    # def build_lineups_recur(self, player, lineup=Lineup()):
    #     if lineup.salary_remaining < 0 or len(lineup.players) == 6:
    #         return lineup
    #     else 
                
    def make_stack(self, replace=False):
        new_lineups = []
        for lineup in self.lineups:
            stacks = {
                "QB": ["TE", "WR", "RB"],
                "RB": ["QB", "DST"],
                "DST": ["RB"],
                "WR": ["QB"],
                "TE": ["QB"]
            }
            multi = False
            for i, player_main in enumerate(lineup.players):
                for player_sup in lineup.players[i+1:]:
                    if player_main.team != player_sup.team:
                        continue
                    
                    if player_sup.position in stacks[player_main.position] or player_main.position in stacks[player_sup.position]:
                        stack = self.describe_stack([player_main.position, player_sup.position])
                        if stack:
                            if lineup.stack and lineup.stack != stack and ("DST" in lineup.stack or "DST" in stack):
                                lineup.stack += f", {stack}"
                                multi = True
                            else:
                                lineup.stack = stack
                        
            if replace and lineup.stack:
                if multi:
                    new_lineups.insert(0, lineup)
                else:
                    new_lineups.append(lineup)
                
        if replace:
            self.lineups = new_lineups

    def restrict_lineups(self, limit=3):
        limit = int(limit)
        players = {}
        restricted_lineups = []
        for lineup in self.lineups:
            nxt = False
            for player in lineup.players:
                if player in players and players[player] >= limit:
                    nxt = True
                    break
            if nxt:
                continue
            for player in lineup.players:
                if player not in players:
                    players[player] = 1
                else:
                    players[player] += 1
            restricted_lineups.append(lineup)
        self.lineups = restricted_lineups

    def describe_stack(self, positions):
        if "QB" in positions:
            if "RB" in positions:
                return "QB-RB"
            elif "WR" in positions:
                return "QB-WR"
            elif "TE" in positions:
                return "QB-TE"
        if "RB" in positions and "DST" in positions:
            return "RB-DST"
        return ""

    def add_values(self, site):
        for player in self.players.values():
            player.get_value(site)
    