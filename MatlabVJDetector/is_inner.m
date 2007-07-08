% is_innerRect
function is_inner = is_innerRect(r1, r2)

if( r1(1) <= r2(1) && r1(3) > r2(3) && r1(2) <= r2(2) && r1(4) > r2(4) )
    is_inner = 1;
else
    is_inner = 0;
end