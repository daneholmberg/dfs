cdef class Player:
    cdef public str name
    cdef public str team
    cdef public str position
    cdef public str flex
    cdef public float median
    cdef public float lower
    cdef public float upper
    cdef public str sdPts
    cdef public str dropoff
    cdef public str sdRank
    cdef public str risk
    cdef public float salary
    cdef public str opposing_team
    cdef public double median_value
    cdef public double upper_value
    cdef public double lower_value
    cpdef update_player_proj(self, data)
    cpdef update_player_dfs(self, data)
    cpdef get_value(self)
    cpdef __deepcopy__(self, memo)