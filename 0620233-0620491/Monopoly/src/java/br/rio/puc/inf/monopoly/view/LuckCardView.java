package br.rio.puc.inf.monopoly.view;

import br.rio.puc.inf.monopoly.model.LuckCard;

import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

import javax.imageio.ImageIO;
import javax.swing.JComponent;

/**
 * <p>
 * </p>
 * 
 * @author ryniere
 * @version 1.0 Created on 10/11/2012
 */
public class LuckCardView
	extends JComponent
{

	/**
	 * <p>
	 * Field <code>serialVersionUID</code>
	 * </p>
	 */
	private static final long serialVersionUID = 1L;

	/**
	 * <p>
	 * </p>
	 * 
	 * @param luckCard
	 */
	public LuckCardView( final LuckCard luckCard )
	{
		super();
		setLuckCard( luckCard );
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @return
	 */
	public LuckCard getLuckCard()
	{
		return this.luckCard;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param g1
	 * @see javax.swing.JComponent#paintComponent(java.awt.Graphics)
	 */
	@Override
	protected void paintComponent( final Graphics g1 )
	{

		try
		{
			final LuckCard luckCard = getLuckCard();
			final BufferedImage image = ImageIO.read( new File( luckCard.getImagePath() ) );

			final Graphics2D g = ( Graphics2D ) g1;
			final Dimension size = getSize();

			// as coordenadas não são mais em pixels, mas relativas ao plano cartesiano definido
			// acima
			g.drawImage( image, null, 0, 0 );

			g.dispose();

		}
		catch ( final IOException e )
		{

		}
	}

	public void setLuckCard( final LuckCard luckCard )
	{
		this.luckCard = luckCard;
	}

	private LuckCard luckCard;

}
