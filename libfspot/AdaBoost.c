#include <stdlib.h>
#include <math.h>
#define MAX_CLS_IN_STAGE 30

int *labels;
int *used;
int **images;
int **features;
int *w;

int pos_count;
int neg_count;
int img_count;
int feat_count;
int t;
int T;
int i;

typedef struct {
	double theta;
	double alpha;
	double error;
	int parity;
} WeakClassifier;

typedef struct {
	
	double theta;
	int cls_count;
	WeakClassifier *cls;
	
} StrongClassifier;

int sum (int *tbl, int len) {
	
	int i;
	int sum=0;
	for(i=0; i<len; i++)
		sum+=tbl[i];
	return sum;
}
/// this in turn requires the image to be in a [x y] matrix !

void IntegralImage (int **img, int **dst, int w, int h) {
	int x,y;
	
	
	// fill in the first line
	dst[0][0]=img[0][0];
	for(x=1; x<w; x++)
		dst[x][0] = dst[x-1][0] + img[x][0];
	
	for(y=1; y<h; y++)
	{
		double line = img[0][y];
		dst[0][y] = dst[0][y-1] + line;
		for(x=0; x<w; x++)
		{
			line += img[x][y];
			dst[x][y] = dst[x][y-1] + line;
		}
	}
	
}

double ApplyFeature(int *f, int *img)
{
	/// f & img have to be vectors, really.
	/// of size 25*25
	int i;
	double wynik = 0.0f;
	for( i=0; i<625; i++)
	{
				wynik+=	f[i]*img[i];
	}
	return wynik;
}


WeakClassifier findWeakClassifier(int *f, int *fxIdx) {
	
	double e1 = 0.0;
	double e2 = 0.0;
	double min1;
	double min2;
	int min1Idx;
	int min2Idx;
	int i,j;
	WeakClassifier cls;
	double Tp,Tn,Sp,Sn;
	
	for(i=0; i<pos_count; i++)
		Tp += w[i];
	for(i=pos_count; i<img_count; i++)
		Tn += w[i];
	e2 = 1-e1;
	min1 = e1;
	min2 = e2;
	for(i=0; i<img_count; i++)
	{
		if(labels[i]==1)
			Sp += w[fxIdx[i]];
		else
			Sn += w[fxIdx[i]];
		
		e1 = ( Sp + (Tn - Sn));
		e2 = ( Sn + (Tp - Sp));
			
		if(e1<min1)
		{
			min1 = e1;
			min1Idx = i;
		}
		if(e2<min2)
		{
			min2 = e2;
			min2Idx = i;
		}
	}
	
	if(min1<min2)
	{
		cls.parity = 1;
		cls.theta = ApplyFeature(f, images[fxIdx[min1Idx]]);
		cls.error = min1;
	}
	else
	{
		cls.parity = -1;
		cls.theta = ApplyFeature(f, images[fxIdx[min2Idx]]);
		cls.error = min2;
	}
	
}		
int AddClassifier (StrongClassifier sc, WeakClassifier cls) {
	
	if(sc.cls_count >= MAX_CLS_IN_STAGE)
		return -1;
	
	sc.cls[sc.cls_count] = cls;
	sc.cls_count++;
	return 0;
	
}


int AdaBoost (StrongClassifier sc) {
	int i,j,T;
	double beta;
	double *alfa;
	int *fxIdx;	
	T = 20; // maximum number of weak classifiers in a strong one
	if(T > MAX_CLS_IN_STAGE) 
		return -1;
	
	img_count = pos_count + neg_count;
	
	for(i=0; i<pos_count; i++)
		labels[i] = 1;
	
	for(i=pos_count; i<img_count; i++)
		labels[i] = -1;
	
	for(i=0; i<img_count; i++)
		if(labels[i])
			w[i] = 0.5*1/pos_count;
		else
			w[i] = 0.5*1/neg_count;
		
	
		/// proceed to boosting round t of T
	for (t=0; t<T; t++)	{
			
		int min_error = 0;
		int min_idx = 0;
	
			/// 1. normalize the weights
		int w_sum = sum(w,img_count);
	
		for(i=0; i<img_count; i++)
			w[i] /= w_sum;
			// end normalize
	 	WeakClassifier cls[feat_count];
			/// 2. For each feature train a classifier h_j which is restricted to using a single feature
			/// The error is evaluated with respect to wt, ej = S_i w_i |h_j(x_i) - y_i|.
			
			 /// Calculate the features and sort by values
		int **x; // the images
		for(j=0; j<feat_count; j++)	{
			
			if(used[j]) 
				continue;
			
			double values[img_count];
			
			for(i=0; i<img_count; i++)
				values[i] = ApplyFeature(features[j],x[i]);
			sort(values,fxIdx);
			
			cls[j] = findWeakClassifier(features[j],fxIdx);
			
			if(cls[j].error < min_error) {
				min_error = cls[j].error;
				min_idx = j;
			}
		}
			
			/// 3. Choose the classifier, h_t, with the lowest eror e_t.
			AddClassifier(sc, cls[min_idx]);
			used[min_idx] = 1;
			/// 4. Update the weights
			
			
			beta = min_error / (1 - min_error);
			alfa[t] = log(1/beta);
			for(i=0; i<img_count; i++)
			{
				
				w[i] = w[i]*pow(beta, 1-abs( labels[i]- ApplyClassifier(cls[min_idx],images[i]) ) );
			}
			sc.theta += 0.5 * alfa[t];
			/// proceed to the next round
			
		}
}

 /// The detector, input: img as a 25*25 vector
 int ApplyStrongClassifier ( StrongClassifier sc, int *img ) {

 	double th=0;
 
 	for (i=0; i<sc.cls_count; i++)
 		th+=sc.cls[t].alpha * ApplyClassifier(sc.cls[t], img);
 
 	return (th<sc.theta)?-1:1;
 }
 
void Detect (int *img) {

//	int th;
	StrongClassifier *sc;
	int notFace = 0;
	
 	for (t=0; t<T && notFace==0; t++)
 	
 		if(!ApplyStrongClassifier(sc[t],img))
			notFace = 1;

 
 	//draw the box
 //	if(!notFace) // draw it	 
}
