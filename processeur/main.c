#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include <SDL/SDL.h>
#include <SDL/SDL_image.h>
#include <SDL/SDL_mixer.h>

#include "control.h"
#include "utility.h"

int max(int a, int b) { return (a < b) ? b : a; }

void blit(int x, int y, SDL_Surface *surface)
{
	SDL_Rect pos = {x,y};
	SDL_BlitSurface(surface, NULL, SDL_GetVideoSurface(), &pos);
}

void print_digit(int x, int y, SDL_Surface *vert, SDL_Surface *horiz, uint8_t digits)
{
	if (digits&0x80)
		blit(x+8, y+4, horiz);
	if (digits&0x40)
		blit(x+3, y+9, vert);
	if (digits&0x20)
		blit(x+40, y+9, vert);
	if (digits&0x10)
		blit(x+8, y+47, horiz);
	if (digits&0x08)
		blit(x+3, y+52, vert);
	if (digits&0x04)
		blit(x+40,y+52, vert);
	if (digits&0x02)
		blit(x+8, y+90, horiz);
}

void cycle(State *st)
{
	compute_cycle(st);
	for (int i = 0 ; i < 4 ; i++)
		st->mem_rs1_data[0][i] = st->mem_rs2_data[0][i] = 0;
}

int main(int argc, char *argv)
{
	State st;
	init_st(&st);
	int n = load_program(&st,"program.bin");

	time_t t = time(NULL);
	struct tm time = *localtime(&t);
	int year = time.tm_year+1900;
	st.mem_mem_rd_data[invert_word(15*4)][3] = invert_byte((uint8_t) (year/1000));
	year %= 1000;
	st.mem_mem_rd_data[invert_word(16*4)][3] = invert_byte((uint8_t) (year/100));
	year %= 100;
	st.mem_mem_rd_data[invert_word(17*4)][3] = invert_byte((uint8_t) year/10);
	year %= 10;
	st.mem_mem_rd_data[invert_word(18*4)][3] = invert_byte((uint8_t) year);
	st.mem_mem_rd_data[invert_word(19*4)][3] = invert_byte((uint8_t) (time.tm_mon+1));
	st.mem_mem_rd_data[invert_word(20*4)][3] = invert_byte((uint8_t) time.tm_mday);
	st.mem_mem_rd_data[invert_word(21*4)][3] = invert_byte((uint8_t) time.tm_hour);
	st.mem_mem_rd_data[invert_word(22*4)][3] = invert_byte((uint8_t) (time.tm_min/10));
	st.mem_mem_rd_data[invert_word(23*4)][3] = invert_byte((uint8_t) (time.tm_min%10));
	st.mem_mem_rd_data[invert_word(24*4)][3] = invert_byte((uint8_t) ((time.tm_sec-1)/10));
	st.mem_mem_rd_data[invert_word(25*4)][3] = invert_byte((uint8_t) ((time.tm_sec-1)%10));

	if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) < 0)
	{
		printf("Erreur SDL : %s\n", SDL_GetError());
		return 1;
	}
	Mix_OpenAudio(44100,MIX_DEFAULT_FORMAT,MIX_DEFAULT_CHANNELS,1024);
	Mix_AllocateChannels(5);
	Mix_Music *music = Mix_LoadMUS("Donnees/ambiance.ogg");

	SDL_Surface *screen = SDL_SetVideoMode(640,400,32,SDL_HWSURFACE|SDL_DOUBLEBUF);
	SDL_WM_SetCaption("Pendule RISC",NULL);

	SDL_Surface *background = IMG_Load("Donnees/arriere_plan.png");
	SDL_Surface *verti = IMG_Load("Donnees/barre_vert.png");
	SDL_Surface *horiz = IMG_Load("Donnees/barre_horiz.png");
	SDL_Surface *dots  = IMG_Load("Donnees/points.png");

	char s[21] = {0};
	SDL_Surface* fire[4] = {0};
	SDL_Surface* mask[4] = {0};
	for (int i = 0 ; i < 4 ; i++)
	{
		sprintf(s,"Donnees/flammes%d.png",i+1);
		fire[i] = IMG_Load(s);
		mask[i] = SDL_CreateRGBSurface(0,640,400,32,0xff000000,0x00ff0000,0x0000ff00,0x000000ff);
		SDL_FillRect(mask[i],NULL,SDL_MapRGBA(mask[i]->format,255,0,0,20+20*i));
	}

	SDL_Event event;

	st.mem_mem_rd_data[0][0] = 1;
	while (st.mem_mem_rd_data[0][0])	
		cycle(&st);

	int stop = 0, nbframes = 0, frenzy = 0, space_pressed = 0;
	while (!stop)
	{
		int t1 = SDL_GetTicks();
		SDL_PollEvent(&event);
		nbframes++;

		switch(event.type)
		{
			case SDL_QUIT:
				stop = 1;
				break;
			case SDL_KEYDOWN:
				if (event.key.keysym.sym == SDLK_SPACE && !space_pressed)
				{
					space_pressed = 1;
					frenzy = !frenzy;
					if (frenzy)
						Mix_PlayMusic(music,-1);
					else
						Mix_HaltMusic();
				}
				if (event.key.keysym.sym == SDLK_ESCAPE)
					stop = 1;
				break;
			case SDL_KEYUP:
				if (event.key.keysym.sym == SDLK_SPACE)
					space_pressed = 0;
				break;
		}

		if (nbframes == 20)
			nbframes = 0;

		if (frenzy)
		{
			while (SDL_GetTicks() - t1 < 50)
			{
				st.mem_mem_rd_data[0][0] = 1;
				while (st.mem_mem_rd_data[0][0])	
					cycle(&st);
			}
		}
		else if (!nbframes)
		{
			nbframes = 0;
			st.mem_mem_rd_data[0][0] = 1;
			while (st.mem_mem_rd_data[0][0])
				cycle(&st);
			for (int i = 0 ; i < 500 ; i++)
				cycle(&st);
		}

		SDL_BlitSurface(background,NULL,screen,NULL);
		print_digit(120,40,verti,horiz,st.mem_mem_rd_data[invert_word(1*4)][3]);
		print_digit(170,40,verti,horiz,st.mem_mem_rd_data[invert_word(2*4)][3]);
		print_digit(220,40,verti,horiz,st.mem_mem_rd_data[invert_word(3*4)][3]);
		print_digit(270,40,verti,horiz,st.mem_mem_rd_data[invert_word(4*4)][3]);
		print_digit(330,40,verti,horiz,st.mem_mem_rd_data[invert_word(5*4)][3]);
		print_digit(380,40,verti,horiz,st.mem_mem_rd_data[invert_word(6*4)][3]);
		print_digit(440,40,verti,horiz,st.mem_mem_rd_data[invert_word(7*4)][3]);
		print_digit(490,40,verti,horiz,st.mem_mem_rd_data[invert_word(8*4)][3]);

		print_digit(160,160,verti,horiz,st.mem_mem_rd_data[invert_word(9*4)][3]);
		print_digit(210,160,verti,horiz,st.mem_mem_rd_data[invert_word(10*4)][3]);
		print_digit(270,160,verti,horiz,st.mem_mem_rd_data[invert_word(11*4)][3]);
		print_digit(320,160,verti,horiz,st.mem_mem_rd_data[invert_word(12*4)][3]);
		print_digit(380,160,verti,horiz,st.mem_mem_rd_data[invert_word(13*4)][3]);
		print_digit(430,160,verti,horiz,st.mem_mem_rd_data[invert_word(14*4)][3]);

		if ((!frenzy && nbframes >= 10) || (frenzy && nbframes%2))
		{
			SDL_Rect pos = {260,160};
			SDL_BlitSurface(dots, NULL, screen, &pos);
			pos.x += 110;
			SDL_BlitSurface(dots, NULL, screen, &pos);
		}

		if (frenzy)
		{
			SDL_BlitSurface(fire[nbframes%4],NULL,screen,NULL);
			SDL_BlitSurface(mask[abs(3-nbframes%7)],NULL,screen,NULL);
		}

		SDL_Flip(screen);

		int t2 = SDL_GetTicks();
		SDL_Delay(max(0,50 - (t2-t1)));
	}

	SDL_FreeSurface(background);
	SDL_FreeSurface(verti);
	SDL_FreeSurface(horiz);
	SDL_FreeSurface(dots);

	for (int i = 0 ; i < 4 ; i++)
	{
		SDL_FreeSurface(fire[i]);
		SDL_FreeSurface(mask[i]);
	}

	Mix_FreeMusic(music);

	SDL_Quit();

	free_st(&st);

	return 0;
}


