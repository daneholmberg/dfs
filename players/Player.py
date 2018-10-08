class Player:
    def __init__(self, name, offset=1):
        self.name = name
        self.offset = offset
        self.flex = False
    
    def update_player_proj(self, data):
        self.team = data['team']
        self.position = data['position']
        self.median = data['points']
        self.lower = data['lower']
        self.upper = data['upper']
        self.sdPts = data['sdPts']
        self.dropoff = data['dropoff']
        self.sdRank = data['sdRank']
        self.risk = data['risk']
    
    def update_player_dfs(self, data):
        self.isFlex = "FLEX" in data['Roster Position']
        self.salary = data['Salary']

    def get_value(self):
        try:
        # if hasattr(self, "salary") and hasattr(self, "median"):
            self.median_value = float(self.median) / (int(self.salary)/1000)
        # if hasattr(self, "salary") and hasattr(self, "lower"):
            self.lower_value = float(self.lower) / (int(self.salary)/1000)
        # if hasattr(self, "salary") and hasattr(self, "upper"):
            self.upper_value = float(self.upper) / (int(self.salary)/1000)
        except:
            pass
    def __str__(self):
        # return f"name: {self.name} " + ", ".join([a for a in dir(self) if "__" not in a])
        # return f"name: {self.name}"
        
        toRet = f"name: {self.name}, position: {self.position}, team: {self.team}, salary: {self.salary}, median: {self.median}, "
        toRet = toRet + f"value: {self.median_value}" if hasattr(self, "median_value") else ""
        return toRet
