# cython: profile=True

import re

from copy import copy, deepcopy

cdef class Player:
    def __init__(self, name, offset=1):
        self.name = name
        self.is_captain = False
        # self.offset = offset
    
    cpdef update_player_proj(self, data):
        self.team = data['team']
        self.position = data['position']
        self.median = float(data['points'])
        if "combined_median" in data:
            self.median = data["combined_median"]
        #if "pff_median" in data:
            #data["pff_median"] = data["pff_median"].decode("utf-8")
        #    print(type(data["pff_median"]), data["pff_median"])
        try:
            self.pff_median = ""
            self.ffa_median = ""
            self.ffa_lower = ""
            self.ffa_upper = ""
            if "pff_median" in data:
                self.pff_median = data['pff_median']
            if "ffa_median" in data:
                self.ffa_median = data['ffa_median']
            if "ffa_lower" in data:
                self.ffa_lower = data['ffa_lower']
            if "ffa_upper" in data:
                self.ffa_upper = data['ffa_upper']

        except TypeError:
            pass

        self.lower = float(data['lower'])
        self.upper = float(data['upper'])
        self.sdPts = data['sdPts']
        self.dropoff = data['dropoff']
        self.sdRank = data['sdRank']
        self.risk = data['risk']
    
    cpdef __deepcopy__(self, memo):
        id_self = id(self)        # memoization avoids unnecesary recursion
        _copy = memo.get(id_self)
        if _copy is None:
            _copy = type(self)(
                deepcopy(self.name, memo)
                )
            memo[id_self] = _copy
            memo[id_self].salary = deepcopy(self.salary)
            memo[id_self].lower = deepcopy(self.lower)
            memo[id_self].upper = deepcopy(self.upper)
            memo[id_self].median = deepcopy(self.median)
            memo[id_self].median_value = self.median_value
            memo[id_self].lower_value = self.lower_value
            memo[id_self].upper_value = self.upper_value
            memo[id_self].name = self.name
            memo[id_self].team = self.team
            memo[id_self].position = self.position
            memo[id_self].opposing_team = self.opposing_team
        return _copy

    cpdef update_player_dfs(self, data, site="DK"):
        # self.isFlex = "FLEX" in data['Roster Position']
        self.salary = float(data['Salary'])
        if site == "DK":
            match = re.match(r'([\w\&]+)@([\w\&]+)', data['Game Info'])

            if data['TeamAbbrev'] == match.group(1):
                self.opposing_team = match.group(2)
            elif data['TeamAbbrev'] == match.group(2):
                self.opposing_team = match.group(1)
        elif site == "yahoo":
            self.opposing_team = data['Opponent']
    
    cpdef make_cpt(self):
        self.salary *= 1.5
        self.upper *= 1.5
        self.median *= 1.5
        self.lower *= 1.5
        self.is_captain = True

    cpdef get_value(self, site):
        divi = 1000 if site == "DK" else 10
        try:
        # if hasattr(self, "salary") and hasattr(self, "median"):
            self.median_value = float(self.median) / (float(self.salary)/divi)
        # if hasattr(self, "salary") and hasattr(self, "lower"):
            self.lower_value = float(self.lower) / (float(self.salary)/divi)
        # if hasattr(self, "salary") and hasattr(self, "upper"):
            self.upper_value = float(self.upper) / (float(self.salary)/divi)
        except:
            pass
    def __str__(self):
        # return f"name: {self.name} " + ", ".join([a for a in dir(self) if "__" not in a])
        # return f"name: {self.name}"
        #return self.name
        toRet = f"name: {self.name}, captain: {self.is_captain}, position: {self.position}, team: {self.team}, salary: {self.salary}, median: {self.median}, "
        toRet += f"value: {self.median_value}" if hasattr(self, "median_value") else ""
        return toRet
