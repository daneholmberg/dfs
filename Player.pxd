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
    cdef public str pff_median
    cdef public str ffa_median
    cdef public str ffa_upper
    cdef public str ffa_lower
    cdef public bint is_captain
    cpdef update_player_proj(self, data)
    cpdef update_player_dfs(self, data, site=*)
    cpdef get_value(self, site)
    cpdef make_cpt(self)
    cpdef __deepcopy__(self, memo)