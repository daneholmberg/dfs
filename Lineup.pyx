# cython: profile=True

cimport Player

from copy import copy, deepcopy

cdef class Lineup:
    def __init__(self, players=[], int cap=50000, new_player=None, bint captain_mode=False):
        if players:
            self.players = players
        else:
            self.players = players
        self.cap = cap
        self.salary_remaining = cap
        self.decrease_salary_remaining()
        self.needed = {"QB": 1, "RB": 2, "WR": 3, "FLEX": 1, "TE": 1, "DST": 1}
        self.len_players = len(self.players)
        for player in self.players:
            self.remove_needed(player.position, player)
        if new_player and self.create_new(new_player):
            self.add_player(player, captain_mode)
            self.len_players += 1

    

    cpdef create_new(self, player):
        sal_remain = self.salary_remaining - int(player.salary)

        if sal_remain < 0:
            return False
        if not hasattr(player, "position"):
            return False
        if not self.remove_needed(player.position, player):
            return False
        return True

    cpdef add_points(self):
        self.points_floor = 0
        self.points_ceil = 0
        self.points_avg = 0
        for player in self.players:
            self.points_floor = self.points_floor + float(player.lower)
            self.points_ceil = self.points_ceil + float(player.upper)
            self.points_avg = self.points_avg + float(player.median)
    
    cpdef get_new_salary(self, diff):
        new_salary = deepcopy(self.salary_remaining)
        for i, player in enumerate(self.players.reverse()):
            if i + 1 > diff:
                break
            new_salary = new_salary + player.salary
        return new_salary

    # REMOVES LAST PLAYER
    def __deepcopy__(self, memo): # memo is a dict of id's to copies
        id_self = id(self)        # memoization avoids unnecesary recursion
        _copy = memo.get(id_self)
        if _copy is None:
            _copy = type(self)()
            memo[id_self] = _copy
            memo[id_self].salary_remaining = self.salary_remaining + int(self.players[-1].salary)
            memo[id_self].needed = self.get_needed_back()
            memo[id_self].players = deepcopy(self.players)[0:-1]

        return _copy

    cpdef get_needed_back(self):
        needed = deepcopy(self.needed)
        last_player = self.players[-1]
        if last_player.position == "QB":
            needed['QB'] = needed['QB'] + 1
        elif last_player.position == "RB":
            if last_player.flex == "True":
                needed['FLEX'] = needed['FLEX'] + 1
            else:
                needed['RB'] = needed['RB'] + 1
        elif last_player.position == "WR":
            if last_player.flex == "True":
                needed['FLEX'] = needed['FLEX'] + 1
            else:
                needed['WR'] = needed['WR'] + 1
        elif last_player.position == "TE":
            if last_player.flex == "True":
                needed['FLEX'] = needed['FLEX'] + 1
            else:
                needed['TE'] = needed['TE'] + 1
        elif last_player.position == "DST":
            needed['DST'] = needed['DST'] + 1
        return needed


    cpdef add_player(self, player, captain_mode):
        #if player.position == "QB" and player.name != "Ben Roethlisberger":
        #    return False
        #if player.name == "Alex Smith" or player.name == "Julio Jones" or player.name == "Jordan Reed" or player.name == "Tevin Coleman"\
        #or player.name == "Jameis Winston" or player.name == "Ezekiel Elliot" or player.name in ["Antonio Brown", "Doug Baldwin"]:
            #return False
        if player.name in ["Geronimo Allison", "Randall Cobb", "Trent Taylor"]:
            return False
        mult = 1.5 if captain_mode else 1
        sal_remain = self.salary_remaining - (int(player.salary) * mult)
        
        if player.name == "Jay Ajayi":
            return False
        if sal_remain < 0:
            return False
        if not player.position:
            return False
        if not captain_mode and not self.remove_needed(player.position, player):
            return False
        #if player.position == "DST" and captain_mode:
        #    return False
        if self.len_players == 0 and captain_mode:
            player_cpt = deepcopy(player)
            player_cpt.salary *= 1.5
            player_cpt.median *= 1.5
            player_cpt.lower *= 1.5
            player_cpt.upper *= 1.5

        self.salary_remaining = self.salary_remaining - float(player.salary)
        if self.len_players == 0 and captain_mode:
            self.players.append(player_cpt)
        else:
            self.players.append(player)
        self.len_players += 1
        return True
    
    cpdef decrease_salary_remaining(self):
        for player in self.players:
            self.salary_remaining = self.salary_remaining - float(player.salary)

    cpdef order_by_pos(self):
        new_order = [None] * 9
        for player in self.players:
            if player.position == "QB":
                new_order[0] = player
            elif player.position == "WR":
                if not new_order[1]:
                    new_order[1] = player
                elif not new_order[2]:
                    new_order[2] = player
                elif not new_order[3]:
                    new_order[3] = player
                elif not new_order[7]:
                    new_order[7] = player
            elif player.position == "RB":
                if not new_order[4]:
                    new_order[4] = player
                elif not new_order[5]:
                    new_order[5] = player
                elif not new_order[7]:
                    new_order[7] = player
            elif player.position == "TE":
                if not new_order[6]:
                    new_order[6] = player
                elif not new_order[7]:
                    new_order[7] = player
            else:
                new_order[8] = player
        self.players = new_order


    def __str__(self):
        plays = f"Points_avg: {self.points_avg}\nSalary remaining: {self.salary_remaining}\nPlayers: {self.len_players}\n"
        for player in self.players:
            plays = f"{plays} {player}\n"
        return plays

    cpdef remove_needed(self, pos, player):
        if pos == "QB":
            if self.needed['QB'] == 0:
                return False
            self.needed['QB'] = self.needed['QB'] - 1
        elif pos == "RB":
            if self.needed['RB'] == 0:
                if self.needed['FLEX'] == 0:
                    return False
                self.needed['FLEX'] = self.needed['FLEX'] - 1
                player.flex = "True"
            else:
                self.needed['RB'] = self.needed['RB'] - 1
        elif pos == "WR":
            if self.needed['WR'] == 0:
                if self.needed['FLEX'] == 0:
                    return False
                self.needed['FLEX'] = self.needed['FLEX'] - 1
                player.flex = "True"
            else:
                self.needed['WR'] = self.needed['WR'] - 1
        elif pos == "TE":
            if self.needed['TE'] == 0:
                if self.needed['FLEX'] == 0:
                    return False
                self.needed['FLEX'] = self.needed['FLEX'] - 1
                player.flex = "True"
            else:
                self.needed['TE'] = self.needed['TE'] - 1
        elif pos == "DST":
            if self.needed['DST'] == 0:
                return False
            self.needed['DST'] = self.needed['DST'] - 1
        return True
