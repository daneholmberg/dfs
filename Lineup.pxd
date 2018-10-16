cdef class Lineup:
    cdef public list players
    cdef int cap
    cdef double salary_remaining
    cdef dict needed
    cdef public int len_players
    cdef public double points_floor
    cdef public double points_ceil
    cdef public double points_avg
    cpdef create_new(self, player)
    cpdef add_points(self)
    cpdef get_new_salary(self, diff)
    cpdef get_needed_back(self)
    cpdef add_player(self, player, captain_mode)
    cpdef decrease_salary_remaining(self)
    cpdef order_by_pos(self)
    cpdef remove_needed(self, pos, player)