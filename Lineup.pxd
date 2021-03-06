cdef class Lineup:
    cdef public list players
    cdef int cap
    cdef public double salary_remaining
    cdef dict needed
    cdef public int len_players
    cdef public double points_floor
    cdef public double points_ceil
    cdef public double points_avg
    cdef public str stack
    cdef dict players_dict
    cdef dict required_players
    cpdef str lineup_type
    cdef bint has_cpt
    cpdef create_new(self, player, captain_mode)
    cpdef add_points(self)
    #cdef check_required(self)
    cpdef get_new_salary(self, diff)
    cpdef get_needed_back(self)
    cpdef add_player(self, player, captain_mode)
    cpdef decrease_salary_remaining(self)
    cpdef order_by_pos(self)
    cpdef remove_needed(self, pos, player)
    cpdef set_needed(self)