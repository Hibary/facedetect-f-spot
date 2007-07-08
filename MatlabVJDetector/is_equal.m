% function determining if rects are equal. the decision is based mostly on
% distance between examined rects' bounds
% OpenCV prototype :
%static int is_equal( const void* _r1, const void* _r2, void* )
%{
%    const CvRect* r1 = (const CvRect*)_r1;
%    const CvRect* r2 = (const CvRect*)_r2;
%    int distance = cvRound(r1->width*0.2);

%    return r2->x <= r1->x + distance &&
%           r2->x >= r1->x - distance &&
%           r2->y <= r1->y + distance &&
%           r2->y >= r1->y - distance &&
%           r2->width <= cvRound( r1->width * 1.2 ) &&
%           cvRound( r2->width * 1.2 ) >= r1->width;
%}

% rect is a [ x y width height ]

function eq = is_equal ( r1, r2 )

dist = round(r1(3)*0.2);
if r2(1) <= r1(1) + dist &&   r2(1) >= r1(1) - dist &&   r2(2) <= r1(2) + dist &&   r2(2) >= r1(2) - dist &&   r2(3) <= round(r1(3)*1.2) &&   round(r2(2)*1.2) >= r1(3)
    eq = 1;
else eq = 0;
end