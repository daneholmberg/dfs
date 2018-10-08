from players.Player import Player

class Team:
    def __init__(self, name):
        self.name = name
        self.players = {}

    def add_update_proj_player(self, data):
        if data['player'] not in self.players:
            self.players[data['player']] = Player(data['player'])
        self.players[data['player']].update_player_proj(data)
    
    def add_update_dsf_player(self, data):
        if data['Name'] not in self.players:
            self.players[data['Name']] = Player(data['Name'])
        self.players[data['Name']].update_player_dfs(data)

    def add_values(self):
        for player in self.players.values():
            player.get_value()

    def __str__(self):
        return f"{self.name} - {self.players}"